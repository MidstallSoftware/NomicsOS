import 'package:nomics_api_control/nomics_api_control.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';

void main(List<String> args) {
  final config = Configuration.fromArgs(args);

  if (config.hotReload) {
    withHotreload(() => createServer(config));
  } else {
    createServer(config);
  }
}
