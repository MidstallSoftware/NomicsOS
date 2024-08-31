import 'dart:convert';
import 'dart:io';
import 'package:git/git.dart';

String readShaFromContent(String str) {
  final i = 7 + str.indexOf('commit ');
  return str.substring(i, str.indexOf('\n', i));
}

Future<Map<String, dynamic>?> flakeMeta(String p) async {
  var proc = await Process.run('nix', [
    'flake',
    'metadata',
    '--json',
    p,
  ]);

  final errno = await proc.exitCode;
  if (errno != 0) return null;
  return json.decode(proc.stdout);
}

Future<Map<String, dynamic>?> readCommit(GitDir repo, Commit commit) async {
  final meta = await flakeMeta('${repo.path}?rev=${readShaFromContent(commit.content)}');
  if (meta == null) return null;

  return {
    'author': commit.author,
    'committer': commit.committer,
    'content': commit.content,
    'message': commit.message,
    'metadata': meta,
  };
}
