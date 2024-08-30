import 'dart:convert';

import '../db.dart';
import '../entities/user.dart';

import 'package:shelf/shelf.dart';

Middleware withAuth({
  required DatabaseContext db,
}) =>
    (innerHandler) => (req) async {
          if (!req.headers.containsKey('authorization')) {
            return Response.unauthorized(
                json.encode({
                  'error': 'INVALID_HDR',
                  'message': 'Missing authorization header',
                }),
                headers: {
                  'Content-Type': 'application/json',
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                });
          }

          final header = req.headers['authorization']!.split(' ');
          if (header.length != 2) {
            return Response.badRequest(
                body: json.encode({
                  'error': 'INVALID_HDR',
                  'message': 'Malformed authorization header',
                }),
                headers: {
                  'Content-Type': 'application/json',
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                });
          }

          if (header[0] != 'Basic') {
            return Response.unauthorized(
                json.encode({
                  'error': 'INVALID_SCM',
                  'message': '${header[0]} is not a supported auth scheme',
                }),
                headers: {
                  'Content-Type': 'application/json',
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                });
          }

          final params = utf8.decode(base64.decode(header[1])).split(':');
          if (params.length != 2) {
            return Response.badRequest(
                body: json.encode({
                  'error': 'INVALID_PRM',
                  'message': 'Malformed authorization params',
                }),
                headers: {
                  'Content-Type': 'application/json',
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                });
          }

          final user = await User.findUser(
            db,
            params[0],
          );

          if (user == null) {
            return Response.unauthorized(
                json.encode({
                  'error': 'INVALID_USR',
                  'message': 'User ${params[0]} does not exist',
                }),
                headers: {
                  'Content-Type': 'application/json',
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                });
          }

          if (!user!.checkPassword(params[1])) {
            return Response.unauthorized(
                json.encode({
                  'error': 'INVALID_PWD',
                  'message': 'Invalid password',
                }),
                headers: {
                  'Content-Type': 'application/json',
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                });
          }

          return Future.sync(() => innerHandler(req.change(
                context: {
                  'user': user,
                },
              ))).then((resp) => resp.change(
                headers: {
                  'WWW-Authenticate':
                      'Basic realm="User access", charset="UTF-8"',
                },
              ));
        };
