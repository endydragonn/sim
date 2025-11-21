package com.gerenciador.eventos.Controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Service.UserService;

/**
 * Controller - endpoints REST da API
 * Camada de apresentação que recebe requisições HTTP
 */
@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired
    private UserService userService;

    /**
     * POST /api/users - Criar novo usuário
     * 
     * Body exemplo:
     * {
     *   "name": "João Silva",
     *   "email": "joao@email.com",
     *   "password": "senha123",
     *   "cpf": "12345678900"
     * }
     */
    @PostMapping
    public ResponseEntity<?> createUser(@RequestBody User user) {
        try {
            User createdUser = userService.createUser(user);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdUser);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro ao criar usuário: " + e.getMessage());
        }
    }

    /**
     * GET /api/users/{id} - Buscar usuário por ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getUserById(@PathVariable Long id) {
        try {
            User user = userService.findById(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * GET /api/users/email/{email} - Buscar usuário por email
     */
    @GetMapping("/email/{email}")
    public ResponseEntity<?> getUserByEmail(@PathVariable String email) {
        try {
            User user = userService.findByEmail(email);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * PUT /api/users/{id} - Atualizar usuário
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User user) {
        try {
            user.setId(id);
            User updatedUser = userService.updateUser(user);
            return ResponseEntity.ok(updatedUser);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro ao atualizar usuário: " + e.getMessage());
        }
    }

    /**
     * DELETE /api/users/{id} - Desativar usuário (soft delete)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            userService.deactivateUser(id);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro ao deletar usuário: " + e.getMessage());
        }
    }

    /**
     * POST /api/users/validate - Validar usuário sem criar
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateUser(@RequestBody User user) {
        String errors = userService.getValidationErrors(user);
        if (errors.isEmpty()) {
            return ResponseEntity.ok().body("Usuário válido");
        } else {
            return ResponseEntity.badRequest().body(errors);
        }
    }

    /**
     * POST /api/users/simple - Criar usuário simples (apenas nome e email)
     * 
     * Body exemplo:
     * {
     *   "name": "Maria",
     *   "email": "maria@email.com"
     * }
     */    
}
