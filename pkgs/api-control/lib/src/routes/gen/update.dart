import 'dart:convert';
import 'dart:io';

import 'common.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> Function(WebSocketChannel) createGenUpdateRoute({
  required String flakeDir,
}) =>
    (webSocket) async {
      final proc = await Process.start('nix', [
        'flake',
        'update',
        '--log-format',
        'internal-json',
        flakeDir,
      ]);

      proc.stderr.listen((ev) {
        String.fromCharCodes(ev).split('\n')
          .where((line) => line.length > 5)
          .map((line) => line.substring(5))
          .forEach((line) {
            webSocket.sink.add(line);
          });
      });

      proc.exitCode.then((c) {
        webSocket.sink.close(1000, 'Process exit with ${c}');
      });
    };
