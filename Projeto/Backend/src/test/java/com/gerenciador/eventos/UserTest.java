package com.gerenciador.eventos;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Service.UserService;
import com.gerenciador.eventos.TestSupport.GlobalDbTruncator;

@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Import(GlobalDbTruncator.class)
public class UserTest {
    
    @Autowired
    private DatabaseConnection databaseConnection;
    
    @Autowired
    private UserService userService;
    
    // Limpeza suite-level via GlobalDbTruncator

    // Limpeza final suite-level via GlobalDbTruncator

    @BeforeEach
    public void isolateUserTable() throws SQLException {
        // Para evitar dependência entre métodos desta classe, limpamos as tabelas dependentes primeiro
        try (Connection conn = databaseConnection.getConnection();
             Statement stmt = conn.createStatement()) {
            // Ordem: primeiro as tabelas que referenciam event, depois event, depois users
            stmt.execute("DELETE FROM public.walletevent");
            stmt.execute("DELETE FROM public.event");
            stmt.execute("DELETE FROM public.mywallet");
            stmt.execute("DELETE FROM public.users");
        }
    }

    // Testando os Getters (ajustados: id, createdAt, updatedAt são gerados pelo banco)
    @Test
    public void testGetId() {
        User objUser = new User();
        objUser.setName("John Doe");
        objUser.setEmail("john.doe@example.com");
        User savedUser = userService.createUser(objUser);
        assertNotNull(savedUser.getId());  // Verifica se foi gerado pelo banco
    }

    @Test
    public void testGetName() {
        User objUser = new User();
        objUser.setName("John Doe");
        assertEquals("John Doe", objUser.getName());
    }

    @Test
    public void testGetEmail() {
        User objUser = new User();
        objUser.setEmail("john.doe@example.com");
        assertEquals("john.doe@example.com", objUser.getEmail());
    }

    @Test
    public void testGetFone() {
        User objUser = new User();
        objUser.setFone("1234567890");
        assertEquals("1234567890", objUser.getFone());
    }

    @Test
    public void testGetPassword() {
        User objUser = new User();
        objUser.setPassword("password123");
        assertEquals("password123", objUser.getPassword());
    }

    @Test
    public void testGetBirthDate() {
        User objUser = new User();
        objUser.setBirthDate("01/01/1990");
        assertEquals("01/01/1990", objUser.getBirthDate());
    }

    @Test
    public void testGetIsAdmin() {
        User objUser = new User();
        objUser.setIsAdmin(true);
        assertTrue(objUser.getIsAdmin());
    }

    @Test
    public void testGetIsActive() {
        User objUser = new User();
        objUser.setIsActive(true);
        assertTrue(objUser.getIsActive());
    }

    @Test
    public void testGetCreatedAt() {
        User objUser = new User();
        objUser.setName("John Doe");
        objUser.setEmail("john.doe@example.com");
        User savedUser = userService.createUser(objUser);
        assertNotNull(savedUser.getCreatedAt());  // Verifica se foi gerado pelo banco
    }

    @Test
    public void testGetUpdatedAt() {
        User objUser = new User();
        objUser.setName("John Doe");
        objUser.setEmail("john.doe@example.com");
        User savedUser = userService.createUser(objUser);
        assertNotNull(savedUser.getUpdatedAt());  // Verifica se foi gerado pelo banco
    }

    // Testando validação de duplicatas (agora salva no PostgreSQL)
    @Test
    public void testValidateDuplicates() {
        // Cria e salva o primeiro usuário
        User firstUser = new User();
        firstUser.setName("John Doe");
        firstUser.setEmail("john.doe@example.com");
        userService.createUser(firstUser);

        // Tenta criar um segundo usuário com o mesmo nome e email
        User secondUser = new User();
        secondUser.setName("John Doe");
        secondUser.setEmail("john.doe@example.com");

        // Verifica se a validação de duplicatas impede a criação
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            userService.createUser(secondUser);
        });
        assertNotNull(exception);
    }

    @Test
    public void testValidateDuplicateEmail() {
        // Cria primeiro usuário
        User firstUser = new User();
        firstUser.setName("John Doe");
        firstUser.setEmail("test@example.com");
        userService.createUser(firstUser);

        // Tenta criar segundo usuário com mesmo email
        User secondUser = new User();
        secondUser.setName("Jane Smith");
        secondUser.setEmail("test@example.com");

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            userService.createUser(secondUser);
        });
        
        assertTrue(exception.getMessage().contains("Email já existente"));
    }

    @Test
    public void testValidateDuplicateName() {
        // Cria primeiro usuário
        User firstUser = new User();
        firstUser.setName("John Doe");
        firstUser.setEmail("john@example.com");
        userService.createUser(firstUser);

        // Tenta criar segundo usuário com mesmo nome
        User secondUser = new User();
        secondUser.setName("John Doe");
        secondUser.setEmail("jane@example.com");

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            userService.createUser(secondUser);
        });
        
        assertTrue(exception.getMessage().contains("Nome já existente"));
    }

    @Test
    public void testValidateDuplicateFone() {
        // Cria primeiro usuário
        User firstUser = new User();
        firstUser.setName("John Doe");
        firstUser.setEmail("john@example.com");
        firstUser.setFone("123.456.789-00");
        userService.createUser(firstUser);

        // Tenta criar segundo usuário com mesmo telefone
        User secondUser = new User();
        secondUser.setName("Jane Smith");
        secondUser.setEmail("jane@example.com");
        secondUser.setFone("123.456.789-00");

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            userService.createUser(secondUser);
        });
        
    assertTrue(exception.getMessage().contains("Telefone já existente"));
    }

    @Test
    public void testSuccessfulUserCreation() {
        // Teste de criação bem-sucedida
        User user = new User();
        user.setName("Valid User");
        user.setEmail("valid@example.com");
        user.setFone("111.222.333-44");
        
        User savedUser = userService.createUser(user);
        
        assertNotNull(savedUser.getId());  // id gerado pelo banco
        assertEquals("Valid User", savedUser.getName());
        assertEquals("valid@example.com", savedUser.getEmail());
        assertNotNull(savedUser.getCreatedAt());  // createdAt gerado pelo banco
        assertNotNull(savedUser.getUpdatedAt());  // updatedAt gerado pelo banco

        // Verifica se foi salvo no banco (query simples)
        try (Connection conn = databaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             java.sql.ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM users")) {
            rs.next();
            assertEquals(1, rs.getInt(1));  // Deve haver 1 usuário
        } catch (SQLException e) {
            fail("Erro ao verificar banco: " + e.getMessage());
        }
    }
}