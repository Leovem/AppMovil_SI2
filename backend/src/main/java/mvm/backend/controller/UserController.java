package mvm.backend.controller;

import mvm.backend.service.UserService;
import mvm.backend.model.UserModel; // Asegúrate de importar la clase Usuario
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import mvm.backend.model.LoginRequest;
//import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@RestController
@RequestMapping("/api/auth")
public class UserController {

    @Autowired
    private UserService usuarioService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        try {
            boolean isValid = usuarioService.validarCredenciales(loginRequest.getEmail(), loginRequest.getPassword());
            if (isValid) {
                return ResponseEntity.ok().body("Inicio de sesión exitoso");
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Credenciales incorrectas");
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error en el servidor");
        }
    }

    // Nuevo método para registrar usuario
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserModel usuario) {
        try {
            usuarioService.registrarUsuario(usuario); // Llama al servicio para registrar al usuario
            return ResponseEntity.status(HttpStatus.CREATED).body("Usuario registrado exitosamente");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error al registrar usuario: " + e.getMessage());
        }
    }
}
