package com.gerenciador.eventos.POJO;

import java.util.ArrayList;
import java.util.List;

/**
 * POJO para receber dados de seed via API
 * Estrutura o payload JSON com usuários, eventos e inscrições
 */
public class SeedData {
    
    private List<User> users;
    private List<Event> events;
    private List<EventWallet> enrollments;
    
    public SeedData() {
        this.users = new ArrayList<>();
        this.events = new ArrayList<>();
        this.enrollments = new ArrayList<>();
    }
    
    // Getters
    public List<User> getUsers() { return users; }
    public List<Event> getEvents() { return events; }
    public List<EventWallet> getEnrollments() { return enrollments; }
    
    // Setters
    public void setUsers(List<User> users) { this.users = users; }
    public void setEvents(List<Event> events) { this.events = events; }
    public void setEnrollments(List<EventWallet> enrollments) { this.enrollments = enrollments; }
}
