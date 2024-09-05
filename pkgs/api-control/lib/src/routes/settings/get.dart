import 'dart:convert';
import '../../module.dart';
import 'package:shelf/shelf.dart';

Handler createSettingsGetRoute({
  required JsonModuleManager modules,
}) =>
    (req) async {
      if (req.url.queryParameters['key'] == null) {
        return Response.badRequest(
          body: json.encode({
            'error': 'INVALID_KEY',
            'message': '"key" is missing from the query in the request.',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }

      return Response.ok(json.encode(await modules.getValue(req.url.queryParameters['key']!)),
          headers: {
            'Content-Type': 'application/json',
          });
    };
