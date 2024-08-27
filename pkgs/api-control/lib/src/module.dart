import 'dart:convert';
import 'dart:io';

class JsonModule {
  final String path;
  final Map<String, dynamic> data;

  const JsonModule({
    required this.path,
    required this.data,
  });

  List<String> get imports => data.containsKey('imports') ? data['imports'] : [];

  static Future<JsonModule> load(String p) async {
    final str = await File(p).readAsString();
    return JsonModule(
      path: p,
      data: json.decode(str),
    );
  }
}
