import 'dart:io';

import 'package:args/args.dart';
import 'package:postgres/postgres.dart';

const kSupportsHotReload =
    bool.fromEnvironment('flags.hot-reload', defaultValue: true);

bool canHotReload() => kSupportsHotReload && Platform.executable == 'dart';

class Configuration {
  final InternetAddress? _address;
  final int? _port;
  final bool? _hotReload;
  final String? _basePath;
  final Endpoint? _pgsqlEndpoint;
  final ConnectionSettings? _pgsqlSettings;
  final String? _rootJsonModule;

  const Configuration({
    InternetAddress? address,
    int? port,
    bool? hotReload,
    String? basePath,
    Endpoint? pgsqlEndpoint,
    ConnectionSettings? pgsqlSettings,
    String? rootJsonModule,
  })  : _address = address,
        _port = port,
        _hotReload = hotReload,
        _basePath = basePath,
        _pgsqlEndpoint = pgsqlEndpoint,
        _pgsqlSettings = pgsqlSettings,
        _rootJsonModule = rootJsonModule;

  InternetAddress get address =>
      _address ?? InternetAddress('0.0.0.0', type: InternetAddressType.IPv4);
  int get port => _port ?? 8080;
  bool get hotReload => _hotReload ?? canHotReload();
  String get basePath => _basePath ?? '/';
  Endpoint get pgsqlEndpoint =>
      _pgsqlEndpoint ?? Endpoint(host: 'localhost', database: 'nomics');
  ConnectionSettings get pgsqlSettings =>
      _pgsqlSettings ?? ConnectionSettings(sslMode: SslMode.disable);
  String get rootJsonModule => _rootJsonModule ?? '/etc/nixos/config.json';

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
          help: 'Sets the base path', defaultsTo: defaults.basePath)
      ..addOption('pgsql-host',
          help: 'Sets the PostgresQL host',
          defaultsTo: defaults.pgsqlEndpoint.host)
      ..addOption('pgsql-port',
          help: 'Sets the PostgresQL port',
          defaultsTo: defaults.pgsqlEndpoint.port.toString())
      ..addOption('pgsql-database',
          help: 'Sets the PostgresQL database',
          defaultsTo: defaults.pgsqlEndpoint.database)
      ..addOption('pgsql-username',
          help: 'Sets the PostgresQL username',
          defaultsTo: defaults.pgsqlEndpoint.username)
      ..addOption('pgsql-password',
          help: 'Sets the PostgresQL password',
          defaultsTo: defaults.pgsqlEndpoint.password)
      ..addFlag('pgsql-socket',
          help: 'Specify that the PostgresQL host is a socket',
          defaultsTo: defaults.pgsqlEndpoint.isUnixSocket)
      ..addOption('root-json-module',
          help: 'Sets the root JSON module to manage config',
          defaultsTo: defaults.rootJsonModule);

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

    final arg_pgsqlHost = results.option('pgsql-host');
    final arg_pgsqlDatabse = results.option('pgsql-database');
    final arg_pgsqlUsername = results.option('pgsql-username');
    final arg_pgsqlPassword = results.option('pgsql-password');

    int? v_pgsqlPort = null;
    final arg_pgsqlPort = results.option('pgsql-port');
    if (arg_pgsqlPort != null) {
      v_pgsqlPort = int.parse(arg_pgsqlPort);
    }

    return Configuration(
      address: v_address,
      port: v_port,
      hotReload: v_hotReload,
      basePath: results.option('base-path'),
      pgsqlEndpoint: Endpoint(
        host: arg_pgsqlHost ?? defaults.pgsqlEndpoint.host,
        database: arg_pgsqlDatabse ?? defaults.pgsqlEndpoint.database,
        username: arg_pgsqlUsername ?? defaults.pgsqlEndpoint.username,
        password: arg_pgsqlPassword ?? defaults.pgsqlEndpoint.password,
        port: v_pgsqlPort ?? defaults.pgsqlEndpoint.port,
        isUnixSocket: results.flag('pgsql-socket'),
      ),
      rootJsonModule:
          results.option('root-json-module') ?? defaults.rootJsonModule,
    );
  }
}
