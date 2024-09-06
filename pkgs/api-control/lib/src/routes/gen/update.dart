import 'dart:convert';
import 'dart:io';

import 'common.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:shelf/shelf.dart';

Handler createGenUpdateRoute({
  required String flakeDir,
}) =>
    webSocketHandler((webSocket) async {
      final proc = await Process.start('nix', [
        'flake',
        'update',
        '--log-format',
        'internal-json',
        flakeDir,
      ],
        environment: {
          'TERM': 'xterm',
        });

      proc.stderr.listen((ev) {
        String.fromCharCodes(ev)
            .split('\n')
            .where((line) => line.length > 5)
            .map((line) => line.substring(5))
            .forEach((line) {
          webSocket.sink.add(line);
        });
      });

      proc.exitCode.then((c) {
        webSocket.sink.close(1000, 'Process exit with ${c}');
      });
    });
