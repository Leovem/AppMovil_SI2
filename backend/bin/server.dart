import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Middleware personalizado para agregar encabezados CORS
Middleware corsHeaders() {
  return (Handler handler) {
    return (Request request) async {
      final response = await handler(request);
      return response.change(headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    };
  };
}

class AuthHandler {
  // Ruta del archivo para guardar usuarios
  final String userFilePath = 'users.json';

  // Método para cargar usuarios desde el archivo
  Future<List<Map<String, dynamic>>> loadUsers() async {
    try {
      final file = File(userFilePath);
      if (!file.existsSync()) {
        return []; // Retorna una lista vacía si el archivo no existe
      }
      final contents = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(contents));
    } catch (e) {
      print('Error al cargar usuarios: $e');
      return [];
    }
  }

  // Método para guardar usuarios en el archivo
  Future<void> saveUser(Map<String, dynamic> user) async {
    final users = await loadUsers();
    users.add(user);
    final file = File(userFilePath);
    await file.writeAsString(jsonEncode(users));
  }

  // Función para hashear la contraseña
  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convertir la contraseña a bytes
    final digest = sha256.convert(bytes); // Hashear usando SHA-256
    return digest.toString(); // Retornar el hash
  }

  // Método para crear el administrador si no existe
  Future<void> createAdminIfNotExists() async {
    final users = await loadUsers();
    final adminUser = users.firstWhere(
      (user) => user['email'] == 'admin@example.com',
      orElse: () =>
          <String, dynamic>{}, // Retorna un mapa vacío en lugar de null
    );

    if (adminUser.isEmpty) {
      // Si no existe, crear un nuevo administrador
      final newAdmin = {
        'nombre': 'Administrador',
        'email': 'admin@example.com',
        'password':
            hashPassword('admin123'), // Hashear la contraseña del administrador
      };
      await saveUser(newAdmin);
      print('Administrador creado.');
    } else {
      print('El administrador ya existe.');
    }
  }

  Handler get handler {
    final router = Router();

    // Endpoint para iniciar sesión
    router.post('/iniciar-sesion', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);

        final email = data['email'];
        final password = data['password'];

        // Cargar usuarios desde el archivo
        final users = await loadUsers();

        // Verificar las credenciales del usuario
        final existingUser = users.firstWhere(
          (user) => user['email'] == email,
          orElse: () => {'email': '', 'password': ''}, // Devuelve un mapa vacío
        );

        if (existingUser['email'] == email) {
          // Comparar la contraseña ingresada con el hash almacenado
          if (existingUser['password'] == hashPassword(password)) {
            return Response.ok(
              jsonEncode({'message': 'Inicio de sesión exitoso!'}),
              headers: {'Content-Type': 'application/json'},
            );
          } else {
            return Response.forbidden(
              jsonEncode({'message': 'Credenciales incorrectas'}),
              headers: {'Content-Type': 'application/json'},
            );
          }
        } else {
          return Response.forbidden(
            jsonEncode({'message': 'Credenciales incorrectas'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'message': 'Error al procesar la solicitud: $e'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Endpoint para registrar un nuevo usuario
    router.post('/registrar', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);

        final name = data['name'];
        final email = data['email'];
        final password = data['password'];

        // Verificar si el usuario ya existe
        final users = await loadUsers();
        final existingUser = users.firstWhere(
          (user) => user['email'] == email,
          orElse: () => {'email': '', 'password': ''}, // Devuelve un mapa vacío
        );

        if (existingUser['email'] == email) {
          return Response.forbidden(
            jsonEncode({'message': 'El usuario ya existe'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Guardar el nuevo usuario en el archivo
        final newUser = {
          'nombre': name,
          'email': email,
          'password': hashPassword(password), // Hashear la contraseña
        };
        await saveUser(newUser);

        return Response.ok(
          jsonEncode({'message': 'Usuario registrado con éxito'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'message': 'Error al procesar la solicitud: $e'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    return router;
  }
}

void main() async {
  // Crear una instancia del manejador
  final authHandler = AuthHandler();

  // Crear el administrador si no existe
  await authHandler.createAdminIfNotExists();

  // Iniciar el servidor utilizando shelf_io y el enrutador
  final server = await shelf_io.serve(
    Pipeline()
        .addMiddleware(logRequests()) // Middleware para registrar solicitudes
        .addMiddleware(corsHeaders()) // Middleware para CORS
        .addHandler(authHandler
            .handler), // Aquí estamos utilizando el enrutador de AuthHandler
    InternetAddress.anyIPv4, // Escucha en todas las interfaces
    8080, // Puerto
  );

  print('Servidor escuchando en http://${server.address.host}:${server.port}');
}
