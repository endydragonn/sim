package com.gerenciador.eventos.POJO;

import java.time.LocalDateTime;

public class EventWallet {
    private Long user_id;
    private Long event_id;    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // construtor vazio
    public EventWallet() {
        this.user_id = null;
        this.event_id = null;
        this.createdAt = null;
        this.updatedAt = null;
    }  

    //construtor completo
    public EventWallet(Long user_id, Long event_id) {
        this.user_id = user_id;
        this.event_id = event_id;
        this.createdAt = null;
        this.updatedAt = null;
    }

    // getters
    public Long getUserId() {return user_id;}

    public Long getEventId() {return event_id;}

    public LocalDateTime getCreatedAt() {return createdAt;}

    public LocalDateTime getUpdatedAt() {return updatedAt;}

    //setters
    public void setUserId(Long user_id) {this.user_id = user_id;}

    public void setEventId(Long event_id) {this.event_id = event_id;}

    public void setCreatedAt(LocalDateTime createdAt) {this.createdAt = createdAt;}

    public void setUpdatedAt(LocalDateTime updatedAt) {this.updatedAt = updatedAt;}

    @Override
    public String toString() {
        return "EventWallet{" +
                "user_id=" + user_id +
                ", event_id=" + event_id +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}
