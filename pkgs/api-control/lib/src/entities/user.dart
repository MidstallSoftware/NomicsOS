import '../db.dart';

import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

class User {
  final DatabaseContext db;

  final int id;
  final String name;
  final DateTime createdAt;
  String? displayName;
  String _password;

  User(
    this.db, {
    required this.id,
    required this.name,
    required this.createdAt,
    this.displayName,
    String password = '',
  }) : _password = password;

  set password(String value) {
    _password = BCrypt.hashpw(value, BCrypt.gensalt());
  }

  bool checkPassword(String input) => BCrypt.checkpw(input, _password);

  static Future<void> createTable(
    DatabaseContext db, {
    bool ifNotExists = true,
  }) async {
    await db.execute('''
      CREATE TABLE${ifNotExists ? " IF NOT EXISTS" : ""} users (
        id bigserial primary key,
        name varchar(32) NOT NULL,
        display_name varchar(255),
        password varchar(255) NOT NULL,
        created_at timestamp default CURRENT_TIMESTAMP,
        UNIQUE (name)
      )
    ''');
  }

  static Future<User> create(
    DatabaseContext db, {
      required String name,
      required String password,
      String? displayName,
    }) async {
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      await db.execute(
        Sql.named('INSERT INTO users (name, password, display_name) VALUES (@name, @password, @display)'),
        parameters: {
          'name': name,
          'password': hashedPassword,
          'display': displayName,
        },
      );

      final results = await db.execute(
        Sql.named('SELECT id,created_at FROM users WHERE name=@name'),
        parameters: {
          'name': name,
        },
      );

      final result = results[0];
      return User(db,
        id: result[0]! as int,
        name: name,
        password: hashedPassword,
        displayName: displayName,
        createdAt: result[1]! as DateTime,
      );
    }

  static Future<User?> findUser(DatabaseContext db, String name) async {
    final results = await db.execute(
      Sql.named('SELECT id,display_name,password,created_at FROM users WHERE name=@name'),
      parameters: {
        'name': name,
      },
    );

    if (results.length < 1) {
      return null;
    }

    final result = results[0];

    return User(db,
      name: name,
      id: result[0]! as int,
      displayName: result[1] as String?,
      password: result[2]! as String,
      createdAt: result[3]! as DateTime,
    );
  }
}
