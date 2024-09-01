import 'dart:convert';
import 'dart:io';

import 'common.dart';

import 'package:git/git.dart';
import 'package:posix/posix.dart';
import 'package:shelf/shelf.dart';

Future<String> _nixVersion() async {
  var nixVer = await Process.run('nix', [
    '--version',
  ]);

  final errno = await nixVer.exitCode;
  if (errno != 0) return '';

  return nixVer.stdout.replaceAll('\n', '');
}

Handler createGenInfoRoute({
  required String flakeDir,
}) =>
    (req) async {
      final repo = await GitDir.fromExisting(flakeDir);

      final un = uname();

      return Response.ok(
        json.encode({
          'nixVersion': await _nixVersion(),
          'branch': (await repo.currentBranch()).branchName,
          'metadata': await flakeMeta(repo.path), 
          'configName': '${un.machine}-linux/${un.nodename}',
        }),
        headers: {
          'Content-Type': 'application/json',
        });
    };
