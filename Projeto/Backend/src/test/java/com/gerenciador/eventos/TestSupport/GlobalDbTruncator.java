package com.gerenciador.eventos.TestSupport;

import java.sql.Connection;
import java.sql.Statement;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.context.TestConfiguration;

import com.gerenciador.eventos.DatabaseConnection;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;

@TestConfiguration
public class GlobalDbTruncator {

    private static final Logger log = LoggerFactory.getLogger(GlobalDbTruncator.class);
    private final DatabaseConnection databaseConnection;

    public GlobalDbTruncator(DatabaseConnection databaseConnection) {
        this.databaseConnection = databaseConnection;
    }

    private void truncateAll() {
        String truncateSQL = "TRUNCATE TABLE public.event, public.walletevent, public.mywallet, public.users RESTART IDENTITY CASCADE";
        try (Connection conn = databaseConnection.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.execute(truncateSQL);
        } catch (Exception e) {
            log.warn("Falha ao truncar tabelas de teste: {}", e.getMessage());
        }
    }

    @PostConstruct
    public void onStart() {
        log.info("[Test] Truncating database at test suite start...");
        truncateAll();
    }

    @PreDestroy
    public void onEnd() {
        log.info("[Test] Truncating database at test suite end...");
        truncateAll();
    }
}
