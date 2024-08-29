import './entities/user.dart';
import 'package:postgres/postgres.dart';

class DatabaseContext {
  final Connection conn;

  const DatabaseContext(this.conn);

  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) =>
      conn.execute(query,
          parameters: parameters,
          ignoreRows: ignoreRows,
          queryMode: queryMode,
          timeout: timeout);

  static Future<DatabaseContext> create(
    Endpoint endpoint, {
    ConnectionSettings? settings,
    bool ifNotExists = true,
  }) async {
    final self =
        DatabaseContext(await Connection.open(endpoint, settings: settings));
    await User.createTable(self, ifNotExists: ifNotExists);
    return self;
  }
}
