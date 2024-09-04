import 'dart:convert';
import 'dart:io' as io;

import 'config.dart';
import 'db.dart';
import 'module.dart';
import 'entities/user.dart';
import 'middleware/with_auth.dart';
import 'routes/gen/apply.dart';
import 'routes/gen/list.dart';
import 'routes/gen/info.dart';
import 'routes/gen/update.dart';
import 'routes/system/status.dart';
import 'routes/settings/get.dart';
import 'routes/settings/set.dart';
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
  var modules = await JsonModuleManager.create(config.rootJsonModule);

  var users = modules.getValue<List>(r'$.users', defaultValue: []) ?? [];

  for (var user in users) {
    var dbUser = await User.findUser(db, user['name']);
    if (dbUser == null) {
      await User.create(db,
          name: user['name'],
          password: user['password'],
          displayName: user['displayName']);
    } else if (user['password'] != null) {
      dbUser.password = user['password'];
      print(user);
      await dbUser.sync();
    }

    user['password'] = null;
  }

  await modules.setValues<List>(r'$.users', users);

  app.all(
      path.posix.join(config.basePath, 'options.json'),
      (req) async => Response.ok(
              await io.File(config.optionsJson).readAsString(),
              headers: {
                'Content-Type': 'application/json',
              }));

  app.all(
      path.posix.join(config.basePath, 'option-pages.json'),
      (req) async => Response.ok(
              await io.File(config.optionPagesJson).readAsString(),
              headers: {
                'Content-Type': 'application/json',
              }));

  app.all(
      path.posix.join(config.basePath, 'gen', 'apply'),
      const Pipeline().addMiddleware(withAuth(db: db)).addHandler(
          createGenApplyRoute(
              modules: modules,
              flakeDir: path.canonicalize(path.absolute(config.flakeDir)))));

  app.get(
      path.posix.join(config.basePath, 'gen', 'list'),
      const Pipeline().addMiddleware(withAuth(db: db)).addHandler(
          createGenListRoute(
              flakeDir: path.canonicalize(path.absolute(config.flakeDir)))));

  app.get(
      path.posix.join(config.basePath, 'gen', 'info'),
      const Pipeline().addMiddleware(withAuth(db: db)).addHandler(
          createGenInfoRoute(
              modules: modules,
              flakeDir: path.canonicalize(path.absolute(config.flakeDir)))));

  app.all(
      path.posix.join(config.basePath, 'gen', 'update'),
      const Pipeline().addMiddleware(withAuth(db: db)).addHandler(
          createGenUpdateRoute(
              flakeDir: path.canonicalize(path.absolute(config.flakeDir)))));

  app.get(
      path.posix.join(config.basePath, 'system', 'status'),
      const Pipeline()
          .addMiddleware(withAuth(db: db))
          .addHandler(createSystemStatusRoute()));

  app.post(
      path.posix.join(config.basePath, 'settings', 'get'),
      const Pipeline()
          .addMiddleware(withAuth(db: db))
          .addHandler(createSettingsGetRoute(modules: modules)));

  app.post(
      path.posix.join(config.basePath, 'settings', 'set'),
      const Pipeline()
          .addMiddleware(withAuth(db: db))
          .addHandler(createSettingsSetRoute(modules: modules)));

  app.post(
      path.posix.join(config.basePath, 'user', 'login'),
      const Pipeline()
          .addMiddleware(withAuth(db: db))
          .addHandler(createUserLoginRoute()));

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
