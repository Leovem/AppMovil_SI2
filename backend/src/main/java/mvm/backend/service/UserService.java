package mvm.backend.service;

import mvm.backend.model.UserModel;
import mvm.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository usuarioRepository;

    private BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public boolean validarCredenciales(String email, String password) {
        Optional<UserModel> usuarioOptional = usuarioRepository.findByEmail(email);

        if (usuarioOptional.isPresent()) {
            UserModel usuario = usuarioOptional.get();
            // Comparar la contraseña cifrada
            return passwordEncoder.matches(password, usuario.getPassword());
        } else {
            return false;
        }
    }

    // Método para registrar un nuevo usuario
    public void registrarUsuario(UserModel usuario) {
        // Cifrar la contraseña antes de guardarla
        String hashedPassword = passwordEncoder.encode(usuario.getPassword());
        usuario.setPassword(hashedPassword); // Asignar la contraseña cifrada
        usuarioRepository.save(usuario); // Guardar el usuario en la base de datos
    }
}
