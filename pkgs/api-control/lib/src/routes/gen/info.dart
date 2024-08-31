import 'dart:convert';
import 'dart:io';

import 'common.dart';

import 'package:git/git.dart';
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

      return Response.ok(
        json.encode({
          'nixVersion': await _nixVersion(),
          'branch': (await repo.currentBranch()).branchName,
          'metadata': await flakeMeta(repo.path), 
        }),
        headers: {
          'Content-Type': 'application/json',
        });
    };
