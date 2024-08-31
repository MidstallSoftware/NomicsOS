import 'common.dart';
import 'dart:convert';
import 'package:git/git.dart';
import 'package:shelf/shelf.dart';

Handler createGenListRoute({
  required String flakeDir,
}) =>
    (req) async {
      final repo = await GitDir.fromExisting(flakeDir);

      return Response.ok(
          json.encode(Map.fromEntries((await Future.wait((await repo.commits())
                  .values
                  .map((value) => readCommit(repo, value))))
              .where((value) => value != null)
              .cast<Map<String, dynamic>>()
              .map((commit) =>
                  MapEntry(readShaFromContent(commit['content']), commit)))),
          headers: {
            'Content-Type': 'application/json',
          });
    };
