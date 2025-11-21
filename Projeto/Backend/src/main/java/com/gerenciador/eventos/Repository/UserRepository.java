package com.gerenciador.eventos.Repository;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.gerenciador.eventos.DatabaseConnection;
import com.gerenciador.eventos.POJO.User;

/**
 * Repository - responsável pelo acesso ao banco de dados
 * Usa DatabaseConnection injetado pelo Spring
 */
@Repository
public class UserRepository {

    @Autowired
    private DatabaseConnection databaseConnection;

    /**
     * Salvar usuário no banco
     */
    public User save(User user) {
        // Adequa aos campos reais do esquema: user_name, email, fone, password, birthdate, admin
        String sql = "INSERT INTO users (user_name, email, fone, password, birthdate, admin) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            // Valores com defaults para respeitar NOT NULL do schema atual
            String nameVal = user.getName();
            String emailVal = user.getEmail();
            String foneVal = user.getFone();
            if (foneVal == null || foneVal.isBlank()) {
                foneVal = (user.getFone() != null && !user.getFone().isBlank()) ? user.getFone() : ("fone" + System.currentTimeMillis());
            }
            String passwordVal = (user.getPassword() != null && !user.getPassword().isBlank()) ? user.getPassword() : "password";
            Date birthdateVal = toSqlDate(user.getBirthDate());
            if (birthdateVal == null) {
                birthdateVal = Date.valueOf(LocalDate.now());
            }
            boolean adminVal = toPrimitive(user.getIsAdmin());

            stmt.setString(1, nameVal);
            stmt.setString(2, emailVal);
            stmt.setString(3, foneVal);
            stmt.setString(4, passwordVal);
            stmt.setDate(5, birthdateVal);
            stmt.setBoolean(6, adminVal);
            stmt.executeUpdate();

            // Recupera o ID gerado pelo banco (user_id)
            ResultSet rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                user.setId(rs.getLong(1));
            }

            // Busca timestamps gerados pelo banco
            fetchTimestamps(user);

            return user;
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao salvar usuário: " + e.getMessage(), e);
        }
    }

    /**
     * Buscar timestamps gerados pelo banco (created_at, updated_at)
     */
    private void fetchTimestamps(User user) {
        if (user.getId() == null) return;
        
        String sql = "SELECT created_at, updated_at FROM users WHERE user_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setLong(1, user.getId());
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                user.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
                user.setUpdatedAt(rs.getTimestamp("updated_at").toLocalDateTime());
            }
        } catch (SQLException e) {
            // Não crítico, apenas loga
            System.err.println("Aviso: não foi possível buscar timestamps: " + e.getMessage());
        }
    }

    /**
     * Verificar se email já existe
     */
    public boolean emailExists(String email) {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, email);
            ResultSet rs = stmt.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao verificar email: " + e.getMessage(), e);
        }
    }

    /**
     * Verificar se nome já existe
     */
    public boolean nameExists(String name) {
        String sql = "SELECT COUNT(*) FROM users WHERE user_name = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, name);
            ResultSet rs = stmt.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao verificar nome: " + e.getMessage(), e);
        }
    }

    /**
     * Verificar se fone já existe
     */
    public boolean foneExists(String fone) {
        String sql = "SELECT COUNT(*) FROM users WHERE fone = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, fone);
            ResultSet rs = stmt.executeQuery();
            return rs.next() && rs.getInt(1) > 0;

        } catch (SQLException e) {
            throw new RuntimeException("Erro ao verificar fone: " + e.getMessage(), e);
        }
    }

    /**
     * Buscar usuário por ID
     */
    public User findById(Long id) {
        String sql = "SELECT * FROM users WHERE user_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setLong(1, id);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
            return null;
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao buscar usuário: " + e.getMessage(), e);
        }
    }

    /**
     * Buscar usuário por email
     */
    public User findByEmail(String email) {
        String sql = "SELECT * FROM users WHERE email = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, email);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return mapResultSetToUser(rs);
            }
            return null;
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao buscar usuário: " + e.getMessage(), e);
        }
    }

    /**
     * Atualizar usuário
     */
    public User update(User user) {
        // Buscar usuário existente para preservar senha
        User existing = findById(user.getId());
        
        String sql = "UPDATE users SET user_name = ?, email = ?, fone = ?, password = ?, " +
                     "birthdate = ?, admin = ? WHERE user_id = ?";
        
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, user.getName());
            stmt.setString(2, user.getEmail());
            stmt.setString(3, user.getFone());
            // Preservar senha existente se não foi fornecida nova senha
            stmt.setString(4, user.getPassword() != null ? user.getPassword() : existing.getPassword());
            Date birthdateVal = toSqlDate(user.getBirthDate());
            if (birthdateVal == null && existing.getBirthDate() != null) {
                birthdateVal = toSqlDate(existing.getBirthDate());
            } else if (birthdateVal == null) {
                birthdateVal = Date.valueOf(LocalDate.now());
            }
            stmt.setDate(5, birthdateVal);
            stmt.setBoolean(6, user.getIsAdmin() != null ? toPrimitive(user.getIsAdmin()) : toPrimitive(existing.getIsAdmin()));
            stmt.setLong(7, user.getId());
            stmt.executeUpdate();

            // Atualiza timestamp
            fetchTimestamps(user);
            
            return user;
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao atualizar usuário: " + e.getMessage(), e);
        }
    }

    /**
     * Deletar usuário (soft delete - apenas marca como inativo)
     */
    public void softDelete(Long id) {
        // Marca como inativo na coluna isActive (schema atual)
        String sql = "UPDATE users SET isActive = false WHERE user_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setLong(1, id);
            stmt.executeUpdate();
            
        } catch (SQLException e) {
            throw new RuntimeException("Erro ao deletar usuário: " + e.getMessage(), e);
        }
    }

    /**
     * Mapear ResultSet para objeto User
     */
    private User mapResultSetToUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getLong("user_id"));
        user.setName(rs.getString("user_name"));
        user.setEmail(rs.getString("email"));
        user.setFone(rs.getString("fone"));
        user.setPassword(rs.getString("password"));
        // birthdate é DATE; converter para string ISO yyyy-MM-dd
        Date bd = rs.getDate("birthdate");
        if (bd != null) {
            user.setBirthDate(bd.toString());
        }
        user.setIsAdmin(rs.getBoolean("admin"));
        user.setIsActive(rs.getBoolean("isactive"));
        
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            user.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        Timestamp updatedAt = rs.getTimestamp("updated_at");
        if (updatedAt != null) {
            user.setUpdatedAt(updatedAt.toLocalDateTime());
        }
        
        return user;
    }

    private boolean toPrimitive(Boolean b) {
        return Boolean.TRUE.equals(b);
    }

    private Date toSqlDate(String dateStr) {
        if (dateStr == null || dateStr.isBlank()) return null;
        try {
            // Tenta ISO-8601 primeiro
            return Date.valueOf(LocalDate.parse(dateStr));
        } catch (DateTimeParseException ex) {
            try {
                // Tenta formato dd/MM/yyyy
                DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy");
                return Date.valueOf(LocalDate.parse(dateStr, fmt));
            } catch (DateTimeParseException ex2) {
                return null;
            }
        }
    }
}
