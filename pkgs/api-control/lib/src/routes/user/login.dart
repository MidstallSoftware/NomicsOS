import 'dart:convert';
import '../../entities/user.dart';
import 'package:shelf/shelf.dart';

Handler createUserLoginRoute() => (req) {
      final user = req.context['user'] as User;
      return Response.ok(
          json.encode({
            'id': user!.id,
            'name': user!.name,
            'createdAt': user!.createdAt.toIso8601String(),
            'displayName': user!.displayName,
          }),
          headers: {
            'Content-Type': 'application/json',
          });
    };
