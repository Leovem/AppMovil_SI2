import 'package:postgres/postgres.dart';

class ConnectionBD {
  // Método para obtener la conexión
  static Future<PostgreSQLConnection> connect() async {
    var connection = PostgreSQLConnection(
      'localhost', // Dirección del servidor (puede ser "localhost")
      5432, // Puerto de PostgreSQL
      'event_bd', // Nombre de la base de datos
      username: 'postgres', // Usuario
      password: '1256', // Contraseña
    );

    // Abre la conexión
    await connection.open();
    print('Conexión exitosa a PostgreSQL');
    return connection;
  }

  // Método para cerrar la conexión
  static Future<void> closeConnection(PostgreSQLConnection connection) async {
    await connection.close();
    print('Conexión cerrada');
  }
}
