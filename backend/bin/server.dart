import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'connectionBD.dart';

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
  Handler get handler {
    final router = Router();

    // Endpoint para iniciar sesión
    router.post('/iniciar-sesion', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);

        final email = data['email'];
        final password = data['password'];

        // Aquí deberías verificar las credenciales del usuario
        if (email == 'test@example.com' && password == 'password') {
          // Credenciales válidas
          return Response.ok(
            jsonEncode({'message': 'Inicio de sesión exitoso!'}),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          // Credenciales inválidas
          return Response.forbidden(
            jsonEncode({'message': 'Credenciales incorrectas'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } catch (e) {
        // Manejo de errores
        return Response.internalServerError(
          body: jsonEncode({'message': 'Error al procesar la solicitud'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Endpoint para registrar un nuevo usuario
    router.post('/registrar', (Request request) async {
      try {
        //final payload = await request.readAsString();
        //final data = jsonDecode(payload);

        //final name = data['name'];
        //final email = data['email'];
        //final password = data['password'];

        // Aquí deberías guardar el usuario en la base de datos
        // Validar si el email ya está registrado, etc.

        // Simulando la inserción en la base de datos
        // Aquí debes agregar la lógica para guardar en tu base de datos

        return Response.ok(
          jsonEncode({'message': 'Registro exitoso!'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'message': 'Error al procesar la solicitud'}),
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

  // Conexión a la base de datos
  var connection = await ConnectionBD.connect();

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
