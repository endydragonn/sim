package com.gerenciador.eventos.POJO;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * POJO puro - apenas dados, sem lógica de negócio ou acesso ao banco
 */
public class User {
    
    // Atributos
    private Long id;
    private String name;
    private String email;
    private String fone;
    private String password;
    private String birthDate;
    private Boolean isAdmin;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Construtor vazio
    public User() {
        this.isAdmin = false;
        this.isActive = true;
    }

    // Construtor com parâmetros principais
    public User(String name, String email, String fone, String password, String birthDate) {
        this.name = name;
        this.email = email;
        this.fone = fone;
        this.password = password;
        this.birthDate = birthDate;
        this.isAdmin = false;
        this.isActive = true;
    }

    // Getters
    @JsonProperty("user_id")
    public Long getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public String getFone() { return fone; }
    public String getPassword() { return password; }
    @JsonProperty("birthdate")
    public String getBirthDate() { return birthDate; }
    public Boolean getIsAdmin() { return isAdmin; }
    public Boolean getIsActive() { return isActive; }
    @JsonProperty("created_at")
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }

    // Setters
    public void setId(Long id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setEmail(String email) { this.email = email; }
    public void setFone(String fone) { this.fone = fone; }
    public void setPassword(String password) { this.password = password; }
    @JsonProperty("birthdate")
    public void setBirthDate(String birthDate) { this.birthDate = birthDate; }
    public void setIsAdmin(Boolean isAdmin) { this.isAdmin = isAdmin; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    @JsonProperty("created_at")
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                ", fone='" + fone + '\'' +
                ", isActive=" + isActive +
                ", createdAt=" + createdAt +
                '}';
    }
}
