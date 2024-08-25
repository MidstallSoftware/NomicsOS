import 'dart:io';

import 'package:args/args.dart';

const kSupportsHotReload =
    bool.fromEnvironment('flags.hot-reload', defaultValue: true);

bool canHotReload() => kSupportsHotReload && Platform.executable == 'dart';

class Configuration {
  final InternetAddress? _address;
  final int? _port;
  final bool? _hotReload;
  final String? _basePath;

  const Configuration({
    InternetAddress? address,
    int? port,
    bool? hotReload,
    String? basePath,
  })  : _address = address,
        _port = port,
        _hotReload = hotReload,
        _basePath = basePath;

  InternetAddress get address =>
      _address ??
      InternetAddress('0.0.0.0', type: InternetAddressType.IPv4);
  int get port => _port ?? 8080;
  bool get hotReload => _hotReload ?? canHotReload();
  String get basePath => _basePath ?? '/';

  static Configuration fromArgs(List<String> args) {
    const defaults = const Configuration();
    var parser = ArgParser()
      ..addOption('address',
          help: 'Sets the address to listen on',
          defaultsTo: defaults.address.address)
      ..addOption('port',
          help: 'Sets the port to listen on',
          defaultsTo: defaults.port.toString())
      ..addOption('base-path',
          help: 'Sets the base path',
          defaultsTo: defaults.basePath);

    if (canHotReload()) {
      parser.addFlag('hot-reload',
          help: 'Enables hot reloading', defaultsTo: defaults.hotReload);
    }

    final results = parser.parse(args);

    InternetAddress? v_address = null;
    final arg_address = results.option('address');
    if (arg_address != null) {
      InternetAddressType? type;
      if (arg_address.contains('/')) {
        type = InternetAddressType.unix;
      } else if (arg_address.contains('.')) {
        type = InternetAddressType.IPv4;
      } else if (arg_address.contains(':')) {
        type = InternetAddressType.IPv6;
      }

      v_address = InternetAddress(arg_address, type: type!);
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
      basePath: results.option('base-path'),
    );
  }
}
