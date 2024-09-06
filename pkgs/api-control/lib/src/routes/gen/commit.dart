import 'dart:convert';
import 'dart:io';

import 'common.dart';
import '../../entities/user.dart';
import '../../module.dart';

import 'package:posix/posix.dart';
import 'package:shelf/shelf.dart';

Handler createGenCommitRoute({
  required JsonModuleManager modules,
  required String flakeDir,
}) =>
    (req) async {
      if (req.url.queryParameters['title'] == null) {
        return Response.badRequest(
          body: json.encode({
            'error': 'INVALID_KEY',
            'message': '"title" is missing from the query in the request.',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }

      final un = uname();
      final hostname =
          modules.getValue<String>(r'$.hostname', defaultValue: un.nodename) ??
              un.nodename;

      final user = req.context['user'] as User;

      final proc = await Process.run(
          'git',
          [
            'commit',
            '-a',
            '-m',
            req.url.queryParameters['title'] ?? '',
          ],
          workingDirectory: flakeDir,
          environment: {
            'GIT_COMMITTER_NAME': user!.name,
            'GIT_COMMITTER_EMAIL':
                '${user!.name}@${un.machine}-linux.${hostname}',
            'GIT_AUTHOR_NAME': user!.name,
            'GIT_AUTHOR_EMAIL': '${user!.name}@${un.machine}-linux.${hostname}',
          });

      return Response.ok(proc.stdout);
    };
