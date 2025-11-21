package com.gerenciador.eventos.POJO;

import java.time.LocalDateTime;

public class MyWallet {
    private Long user_id;    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // construtor vazio
    public MyWallet() {
        this.user_id = null;
        this.createdAt = null;
        this.updatedAt = null;
    }

    //construtor completo
    public MyWallet(Long user_id) {
        this.user_id = user_id;
        // createdAt/updatedAt são gerados pelo banco
        this.createdAt = null;
        this.updatedAt = null;
    }

    // getters
    public Long getUserId() {return user_id;}

    public LocalDateTime getCreatedAt() {return createdAt;}

    public LocalDateTime getUpdatedAt() {return updatedAt;}

    //setters
    public void setUserId(Long user_id) {this.user_id = user_id;}

    public void setCreatedAt(LocalDateTime createdAt) {this.createdAt = createdAt;}

    public void setUpdatedAt(LocalDateTime updatedAt) {this.updatedAt = updatedAt;}

    @Override
    public String toString() {
        return "MyWallet{" +
                "user_id=" + user_id +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}
