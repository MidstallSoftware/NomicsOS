import 'dart:convert';
import 'dart:io' as io;

import 'config.dart';
import 'db.dart';
import 'routes/user/login.dart';

import 'package:path/path.dart' as path;
import 'package:posix/posix.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<io.HttpServer> createServer(Configuration config) async {
  var app = Router();
  var db = await DatabaseContext.create(config.pgsqlEndpoint,
      settings: config.pgsqlSettings);

  app.post(
      path.posix.join(config.basePath, 'user', 'login'),
      createUserLoginRoute(
        db: db,
      ));

  var handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(app);

  if (config.address.type == io.InternetAddressType.unix) {
    final sock = io.File(config.address.address);
    if (await sock.exists()) {
      await sock.delete();
    }
  }

  var server = await shelf_io.serve(handler, config.address, config.port);

  if (io.Platform.isLinux &&
      config.address.type == io.InternetAddressType.unix) {
    chmod(config.address.address, "666");
  }

  server.autoCompress = true;

  print('Serving at http://${server.address.address}:${server.port}');
  return server;
}
