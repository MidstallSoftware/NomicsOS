import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:posix/posix.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

const kSupportsHotReload =
    bool.fromEnvironment('flags.hot-reload', defaultValue: true);

bool canHotReload() => kSupportsHotReload && io.Platform.executable == 'dart';

class Configuration {
  final io.InternetAddress? _address;
  final int? _port;
  final bool? _hotReload;

  const Configuration({
    io.InternetAddress? address,
    int? port,
    bool? hotReload,
  })  : _address = address,
        _port = port,
        _hotReload = hotReload;

  io.InternetAddress get address =>
      _address ??
      io.InternetAddress('0.0.0.0', type: io.InternetAddressType.IPv4);
  int get port => _port ?? 8080;
  bool get hotReload => _hotReload ?? canHotReload();

  static Configuration fromArgs(List<String> args) {
    const defaults = const Configuration();
    var parser = ArgParser()
      ..addOption('address',
          help: 'Sets the address to listen on',
          defaultsTo: defaults.address.address)
      ..addOption('port',
          help: 'Sets the port to listen on',
          defaultsTo: defaults.port.toString());

    if (canHotReload()) {
      parser.addFlag('hot-reload',
          help: 'Enables hot reloading', defaultsTo: defaults.hotReload);
    }

    final results = parser.parse(args);

    io.InternetAddress? v_address = null;
    final arg_address = results.option('address');
    if (arg_address != null) {
      io.InternetAddressType? type;
      if (arg_address.contains('/')) {
        type = io.InternetAddressType.unix;
      } else if (arg_address.contains('.')) {
        type = io.InternetAddressType.IPv4;
      } else if (arg_address.contains(':')) {
        type = io.InternetAddressType.IPv6;
      }

      v_address = io.InternetAddress(arg_address, type: type!);
    }

    int? v_port = null;
    final arg_port = results.option('port');
    if (arg_port != null) {
      v_port = int.parse(arg_port);
    }

    bool? v_hotReload = null;
    if (parser.findByNameOrAlias('hot-reload') != null) {
      v_hotReload = results.flag('hot-reload');
    }

    return Configuration(
      address: v_address,
      port: v_port,
      hotReload: v_hotReload,
    );
  }
}

void main(List<String> args) {
  final config = Configuration.fromArgs(args);

  print(io.Platform.executable);

  if (config.hotReload) {
    withHotreload(() => createServer(config));
  } else {
    createServer(config);
  }
}

Future<io.HttpServer> createServer(Configuration config) async {
  var app = Router();

  var handler = const Pipeline().addMiddleware(logRequests()).addHandler(app);

  if (config.address.type == io.InternetAddressType.unix) {
    final sock = io.File(config.address.address);
    if (await sock.exists()) {
      await sock.delete();
    }
  }

  var server = await shelf_io.serve(handler, config.address, config.port);

  if (io.Platform.isLinux && config.address.type == io.InternetAddressType.unix) {
    chmod(config.address.address, "666");
  }

  server.autoCompress = true;

  print('Serving at http://${server.address.address}:${server.port}');
  return server;
}
