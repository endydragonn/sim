package com.gerenciador.eventos;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

import com.gerenciador.eventos.TestSupport.GlobalDbTruncator;

@SpringBootTest
@Import(GlobalDbTruncator.class)
public class SchemaValidationTest {

    @Autowired
    private DatabaseConnection databaseConnection;

    @Test
    void shouldHaveRequiredTables() throws Exception {
        assertTrue(tableExists("public", "users"), "Tabela 'users' não existe");
        assertTrue(tableExists("public", "event"), "Tabela 'event' não existe");
        assertTrue(tableExists("public", "mywallet"), "Tabela 'mywallet' não existe");
        assertTrue(tableExists("public", "walletevent"), "Tabela 'walletevent' não existe");
    }

    @Test
    void usersTableShouldHaveKeyColumns() throws Exception {
        assertColumns("users",
            "user_id", "user_name", "email", "fone", "password", "birthdate",
            "admin", "isactive", "created_at", "updated_at"
        );
    }

    @Test
    void eventTableShouldHaveKeyColumns() throws Exception {
        assertColumns("event",
            "event_id", "creator_id", "event_name", "ead", "address",
            "event_date", "buy_time_limit", "capacity", "quant", "description",
            "created_at", "updated_at"
        );
    }

    @Test
    void myWalletTableShouldHaveKeyColumns() throws Exception {
        assertColumns("mywallet",
            "user_id", "created_at", "updated_at"
        );
    }

    @Test
    void walletEventTableShouldHaveKeyColumns() throws Exception {
        assertColumns("walletevent",
            "user_id", "event_id", "created_at", "updated_at"
        );
    }

    private boolean tableExists(String schema, String table) throws Exception {
        String sql = "select count(*) from information_schema.tables where table_schema = ? and table_name = ?";
        try (Connection c = databaseConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, schema);
            ps.setString(2, table);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private void assertColumns(String table, String... expected) throws Exception {
        String sql = "select column_name from information_schema.columns where table_schema = 'public' and table_name = ?";
        Set<String> expectedSet = new HashSet<>(Arrays.asList(expected));
        Set<String> actual = new HashSet<>();
        try (Connection c = databaseConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, table);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    actual.add(rs.getString(1).toLowerCase());
                }
            }
        }
        assertTrue(actual.containsAll(lower(expectedSet)),
            () -> "Colunas faltando na tabela '" + table + "': " + diff(lower(expectedSet), actual));
    }

    private Set<String> lower(Set<String> in) {
        Set<String> out = new HashSet<>();
        for (String s : in) out.add(s.toLowerCase());
        return out;
    }

    private Set<String> diff(Set<String> expected, Set<String> actual) {
        Set<String> d = new HashSet<>(expected);
        d.removeAll(actual);
        return d;
    }
}
