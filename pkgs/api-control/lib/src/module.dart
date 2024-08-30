import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:json_path/src/expression/expression.dart';
import 'package:json_path/src/expression/nodes.dart';
import 'package:json_path/src/fun/fun_factory.dart';
import 'package:json_path/src/grammar/json_path.dart';
import 'package:json_path/src/json_path_internal.dart';
import 'package:json_path/src/node.dart';
import 'package:json_path/src/node_match.dart';
import 'package:json_path/json_path.dart';

dynamic _setByPath(dynamic input, String p, dynamic value) {
  if (p.length == 0) return value;
  p = p.replaceAll('["', '.').replaceAll('"]', '').replaceAll('[\'', '.').replaceAll('\']', '').replaceFirst('\$.', '');

  final parts = p.split('.');

  if (input is Map<String, dynamic> || input is Map<dynamic, dynamic>) {
    final key = parts[0];
    final rest = parts.skip(1).toList();

    if (rest.length > 0 && !input.containsKey(key)) {
      input[key] = {};
    }

    input[key] = _setByPath(input[key], rest.join('.'), value);
  }
  return input;
}

class JsonModule {
  final String path;
  Map<String, dynamic> data;

  JsonModule({
    required this.path,
    required this.data,
  });

  List<String> get imports =>
      data.containsKey('imports') ? data['imports'].cast<String>() : [];

  Future<void> write() async {
    final str = json.encode(data);
    await File(this.path).writeAsString(str);
  }

  static Future<JsonModule> load(String p) async {
    final str = await File(p).readAsString();
    return JsonModule(
      path: p,
      data: json.decode(str),
    );
  }
}

class JsonModuleLookup<T> {
  final T value;
  final String path;
  final String modulePath;

  const JsonModuleLookup({
    required this.value,
    required this.path,
    required this.modulePath,
  });

  @override
  String toString() =>
      'JsonModuleLookup(value: ${value}, path: ${this.path}, modulePath: ${modulePath})';
}

class JsonModuleManager {
  final List<JsonModule> _modules;

  JsonModuleManager({
    List<JsonModule>? modules,
  }) : _modules = modules ?? List.empty(growable: true);

  JsonModule? getModule(String p) {
    for (final mod in _modules) {
      if (mod.path == p) return mod;
    }
    return null;
  }

  void clearModules() {
    _modules.clear();
  }

  Future<JsonModule> load(String p) async {
    var mod = getModule(p);
    if (mod == null) {
      mod = await JsonModule.load(
          path.canonicalize(path.absolute(path.dirname(p), path.basename(p))));
      _modules.add(mod!);

      for (final dep in mod!.imports) {
        await load(
            path.canonicalize(path.absolute(path.dirname(mod.path), dep)));
      }
    }
    return mod;
  }

  T? getValue<T>(String p, {T? defaultValue}) {
    final values = getValues<T>(p);
    if (values.length == 0) return defaultValue;
    return values[0];
  }

  List<T> getValues<T>(String p) {
    return lookupValues<T>(p)
        .map((lookup) => lookup.value)
        .where((value) => value != null)
        .toList()
        .cast();
  }

  Future<void> setValues<T>(String p, T value) async {
    final values = lookupValues<T>(p);
    Map<String, JsonModule> toWrite = {};

    if (values.length > 0) {
      for (final val in values) {
        var module = await load(val.modulePath);
        module.data = _setByPath(
            module.data,
            val.path.replaceAllMapped(RegExp(r"\[\'[a-zA-Z]+\'\]"),
                (m) => '.' + m[0]!.substring(2, m[0]!.length - 2)),
            value);

        if (!toWrite.containsKey(val.modulePath)) {
          toWrite[val.modulePath] = module;
        }
      }
    }

    for (final module in toWrite.values) {
      await module.write();
    }
  }

  List<JsonModuleLookup<T?>> lookupValues<T>(String p, {T? defaultValue}) {
    final parser =
        JsonPathGrammarDefinition(FunFactory([])).build<Expression<NodeList>>();
    final parsed = parser.parse(p);
    final jp = JsonPathInternal(p, parsed.value.call);

    List<JsonModuleLookup<T?>> values = [];
    for (final mod in _modules) {
      final nodes = jp.selector(Node(mod.data));
      values.addAll(nodes
          .where((node) => node.value is T)
          .map(NodeMatch.new)
          .map((node) => JsonModuleLookup(
              value: node.value as T, path: node.path, modulePath: mod.path)));
    }

    if (values.length == 0) {
      final i = p.lastIndexOf(']') > p.lastIndexOf('.')
          ? p.lastIndexOf('[')
          : p.lastIndexOf('.');
      final left = p.substring(0, i);
      final right = p.substring(i);
      return lookupValues(left)
          .map((lookup) => JsonModuleLookup(
                value: defaultValue,
                path: '${lookup.path}${right}',
                modulePath: lookup.modulePath,
              ))
          .toList();
    }

    if (values.where((v) => v.value != defaultValue).length > 0) {
      return values.where((v) => v.value != defaultValue).toList();
    }
    return values;
  }

  static Future<JsonModuleManager> create(String p) async {
    var self = JsonModuleManager();
    await self.load(p);
    return self;
  }
}
