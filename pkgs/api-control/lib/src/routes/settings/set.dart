import 'dart:convert';
import '../../module.dart';
import 'package:shelf/shelf.dart';

Handler createSettingsSetRoute({
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

      if (req.url.queryParameters['value'] == null) {
        return Response.badRequest(
          body: json.encode({
            'error': 'INVALID_KEY',
            'message': '"value" is missing from the query in the request.',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }

      await modules.setValues(req.url.queryParameters['key']!,
          json.decode(req.url.queryParameters['value']!));
      return Response.ok(
          json.encode(await modules.getValue(req.url.queryParameters['key']!)),
          headers: {
            'Content-Type': 'application/json',
          });
    };
