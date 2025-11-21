package com.gerenciador.eventos.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.gerenciador.eventos.DatabaseConnection;
import com.gerenciador.eventos.POJO.EventWallet;

/**
 * Repository JDBC para a tabela de junção walletevent (user_id, event_id).
 */
@Repository
public class EventWalletRepository {

    @Autowired
    private DatabaseConnection databaseConnection;

    /** Inserir vínculo user-event */
    public EventWallet save(EventWallet ew) {
        if (ew.getUserId() == null || ew.getEventId() == null) {
            throw new IllegalArgumentException("user_id e event_id são obrigatórios");
        }
        String sql = "INSERT INTO walletevent (user_id, event_id) VALUES (?, ?)";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, ew.getUserId());
            stmt.setLong(2, ew.getEventId());
            stmt.executeUpdate();
            fetchTimestamps(ew);
            return ew;
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao vincular evento à carteira: " + ex.getMessage(), ex);
        }
    }

    /** Verificar se o vínculo já existe */
    public boolean exists(Long userId, Long eventId) {
        String sql = "SELECT COUNT(*) FROM walletevent WHERE user_id = ? AND event_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.setLong(2, eventId);
            ResultSet rs = stmt.executeQuery();
            return rs.next() && rs.getInt(1) > 0;
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao verificar vínculo carteira-evento: " + ex.getMessage(), ex);
        }
    }

    /** Listar vínculos por usuário */
    public List<EventWallet> findAllByUserId(Long userId) {
        String sql = "SELECT * FROM walletevent WHERE user_id = ?";
        List<EventWallet> out = new ArrayList<>();
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                out.add(map(rs));
            }
            return out;
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao listar vínculos da carteira: " + ex.getMessage(), ex);
        }
    }

    /** Apagar vínculo */
    public void delete(Long userId, Long eventId) {
        String sql = "DELETE FROM walletevent WHERE user_id = ? AND event_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, userId);
            stmt.setLong(2, eventId);
            stmt.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException("Erro ao apagar vínculo carteira-evento: " + ex.getMessage(), ex);
        }
    }

    // ===== Helpers =====
    private void fetchTimestamps(EventWallet ew) {
        String sql = "SELECT created_at, updated_at FROM walletevent WHERE user_id = ? AND event_id = ?";
        try (Connection conn = databaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, ew.getUserId());
            stmt.setLong(2, ew.getEventId());
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                Timestamp c = rs.getTimestamp("created_at");
                if (c != null) ew.setCreatedAt(c.toLocalDateTime());
                Timestamp u = rs.getTimestamp("updated_at");
                if (u != null) ew.setUpdatedAt(u.toLocalDateTime());
            }
        } catch (SQLException ex) {
            System.err.println("Aviso: não foi possível buscar timestamps do vínculo: " + ex.getMessage());
        }
    }

    private EventWallet map(ResultSet rs) throws SQLException {
        EventWallet ew = new EventWallet();
        ew.setUserId(rs.getLong("user_id"));
        ew.setEventId(rs.getLong("event_id"));
        Timestamp c = rs.getTimestamp("created_at");
        if (c != null) ew.setCreatedAt(c.toLocalDateTime());
        Timestamp u = rs.getTimestamp("updated_at");
        if (u != null) ew.setUpdatedAt(u.toLocalDateTime());
        return ew;
    }
}
