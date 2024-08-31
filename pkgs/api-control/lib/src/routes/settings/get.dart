import 'dart:convert';
import '../../module.dart';
import 'package:shelf/shelf.dart';

Handler createSettingsGetRoute({
  required JsonModuleManager modules,
}) =>
    (req) async {
      final content_type = req.headers['content-type'] ?? 'application/json';
      if (content_type != 'application/json') {
        return Response.badRequest(
          body: json.encode({
            'error': 'INVALID_HDR',
            'message': 'Unsupported Content-Type',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }

      final data =
          json.decode(await req.readAsString()) as Map<String, dynamic>;
      if (data['key'] == null) {
        return Response.badRequest(
          body: json.encode({
            'error': 'INVALID_KEY',
            'message': '"key" is missing from JSON body in the request.',
          }),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }

      return Response.ok(json.encode(await modules.getValue(data['key'])),
          headers: {
            'Content-Type': 'application/json',
          });
    };
