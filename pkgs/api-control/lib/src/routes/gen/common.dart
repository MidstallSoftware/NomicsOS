import 'dart:convert';
import 'dart:io';
import 'package:git/git.dart';

String readShaFromContent(String str) {
  final i = 7 + str.indexOf('commit ');
  return str.substring(i, str.indexOf('\n', i));
}

Future<Map<String, dynamic>?> readCommit(GitDir repo, Commit commit) async {
  var flakeShow = await Process.run('nix', [
    'flake',
    'metadata',
    '--json',
    '${repo.path}?rev=${readShaFromContent(commit.content)}',
  ]);

  final errno = await flakeShow.exitCode;
  if (errno != 0) return null;

  return {
    'author': commit.author,
    'committer': commit.committer,
    'content': commit.content,
    'message': commit.message,
    'metadata': json.decode(flakeShow.stdout)
  };
}
