package com.gerenciador.eventos.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.gerenciador.eventos.DatabaseConnection;
import com.gerenciador.eventos.POJO.MyWallet;

/**
 * Repository JDBC para tabela mywallet.
 */
@Repository
public class MyWalletRepository {

    @Autowired
    private DatabaseConnection databaseConnection;

    /**
     * Garante que a carteira exista para o userId informado.
     * No banco, a carteira é criada por trigger ao inserir o usuário; este método é idempotente.
     * Usa INSERT ... ON CONFLICT DO NOTHING para não falhar caso já exista.
     */
    public MyWallet ensureExists(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("user_id é obrigatório");
        }
        String sql = "INSERT INTO mywallet (user_id) VALUES (?) ON CONFLICT (user_id) DO NOTHING";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao garantir carteira: " + ex.getMessage(), ex);
        }
        return findByUserId(userId);
    }

    /** Buscar carteira por user_id */
    public MyWallet findByUserId(Long userId) {
        String sql = "SELECT * FROM mywallet WHERE user_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return map(rs);
            }
            return null;
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao buscar carteira: " + ex.getMessage(), ex);
        }
    }

    /** Verificar se a carteira existe para o usuário */
    public boolean existsByUserId(Long userId) {
        String sql = "SELECT 1 FROM mywallet WHERE user_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            ResultSet rs = stmt.executeQuery();
            return rs.next();
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao verificar existência da carteira: " + ex.getMessage(), ex);
        }
    }

    /** Remover carteira (normalmente não utilizado; FK usa ON DELETE CASCADE em users) */
    public void deleteByUserId(Long userId) {
        String sql = "DELETE FROM mywallet WHERE user_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao deletar carteira: " + ex.getMessage(), ex);
        }
    }


    private MyWallet map(ResultSet rs) throws SQLException {
        MyWallet w = new MyWallet();
        w.setUserId(rs.getLong("user_id"));
        Timestamp c = rs.getTimestamp("created_at");
        if (c != null) w.setCreatedAt(c.toLocalDateTime());
        Timestamp u = rs.getTimestamp("updated_at");
        if (u != null) w.setUpdatedAt(u.toLocalDateTime());
        return w;
    }
}
