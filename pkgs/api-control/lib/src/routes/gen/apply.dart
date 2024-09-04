import 'dart:convert';
import 'dart:io';

import 'common.dart';
import '../../module.dart';

import 'package:posix/posix.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf.dart';

Handler createGenApplyRoute({
  required JsonModuleManager modules,
  required String flakeDir,
}) =>
    (req) => webSocketHandler((webSocket) async {
          final un = uname();
          final hostname = modules.getValue<String>(r'$.hostname',
                  defaultValue: un.nodename) ??
              un.nodename;

          final proc = await Process.start('nixos-rebuild', [
            'switch',
            '--log-format',
            'internal-json',
            '--flake',
            '${req.url.queryParameters.containsKey('commit') ? '${flakeDir}?rev=${req.url.queryParameters['commit']}' : flakeDir}#${un.machine}-linux/${hostname}',
          ]);

          proc.stderr.listen((ev) {
            String.fromCharCodes(ev)
                .split('\n')
                .where((line) => line.startsWith('@nix '))
                .map((line) => line.substring(5))
                .forEach((line) {
              webSocket.sink.add(line);
            });
          });

          proc.exitCode.then((c) {
            webSocket.sink.close(1000, 'Process exit with ${c}');
          });
        })(req);
