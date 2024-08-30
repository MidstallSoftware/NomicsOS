import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:system_info2/system_info2.dart';

Future<List<double>> _loadavg() async =>
    (await File('/proc/loadavg').readAsString())
        .replaceAll('\n', '')
        .split(' ')
        .sublist(0, 3)
        .map((i) => double.parse(i))
        .toList();

Future<List<Map<String, dynamic>>> _lscpu() async {
  final pstat = (await File('/proc/stat').readAsString()).split('\n');
  return (await File('/proc/cpuinfo').readAsString())
      .split('\n\n')
      .where((str) => str.length > 0)
      .map((str) {
    var proc = Map.fromEntries(str.split('\n').map((line) {
      final entry = line.split(': ');
      var key = entry[0].replaceAll('\t', '');
      dynamic value = entry[1];

      switch (key) {
        case 'processor':
        case 'CPU implementer':
        case 'CPU architecture':
        case 'CPU variant':
        case 'CPU part':
        case 'CPU revision':
          key = key.toLowerCase().replaceAll(' ', '_');
          value = int.parse(value);
          break;
        case 'BogoMIPS':
          key = 'bogomips';
          value = double.parse(value);
          break;
        case 'Features':
          key = 'features';
          value = value.split(' ');
          break;
      }
      return MapEntry(key, value);
    }));

    final core_key = 'cpu${proc['processor']}';
    proc['stats'] = pstat.firstWhere((str) => str.startsWith(core_key)).substring(core_key.length + 1).split(' ').map((i) => int.parse(i)).toList();

    return proc;
  }).toList();
}

Handler createSystemStatusRoute() => (req) async {
      return Response.ok(
        json.encode({
          'loadavg': await _loadavg(),
          'cpu': await _lscpu(),
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    };