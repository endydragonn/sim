package com.gerenciador.eventos.Controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gerenciador.eventos.POJO.Event;
import com.gerenciador.eventos.Service.EventService;

/**
 * Controller REST para operações com Event (POJO simples)
 */
@RestController
@RequestMapping("/api/events")
public class EventController {

    @Autowired
    private EventService eventService;

    /**
     * POST /api/events - Criar novo evento (sem persistir)
     */
    @PostMapping
    public ResponseEntity<?> createEvent(@RequestBody Event event) {
        // validações básicas do payload (campos óbvios)
        List<String> basicErrors = validate(event);
        if (!basicErrors.isEmpty()) {
            return ResponseEntity.badRequest().body(String.join("; ", basicErrors));
        }

        // validações de negócio + persistência
        try {
            Event saved = eventService.createEvent(event);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
        }
    }

    /**
     * POST /api/events/validate - Validar evento sem criar
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateEvent(@RequestBody Event event) {
        // validações básicas
        List<String> errors = validate(event);
        // validações do service (regras + duplicidade + existência do criador)
        String serviceErrors = eventService.getValidationErrors(event);
        if (!serviceErrors.isBlank()) {
            errors.add(serviceErrors);
        }
        if (errors.isEmpty()) {
            return ResponseEntity.ok("Evento válido");
        }
        return ResponseEntity.badRequest().body(String.join("; ", errors));
    }

    /**
     * GET /api/events/{id} - Stub até existir persistência
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        try {
            Event e = eventService.findById(id);
            return ResponseEntity.ok(e);
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
        }
    }

    /**
     * PUT /api/events/{id} - Stub até existir persistência
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody Event event) {
        // força o id do path no payload
        if (event.getEvent_id() == null) {
            event.setEvent_id(id);
        } else if (!id.equals(event.getEvent_id())) {
            return ResponseEntity.badRequest().body("ID do path difere do body");
        }

        // validações básicas
        List<String> basicErrors = validate(event);
        if (!basicErrors.isEmpty()) {
            return ResponseEntity.badRequest().body(String.join("; ", basicErrors));
        }

        try {
            Event updated = eventService.updateEvent(event);
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
        }
    }

    /**
     * DELETE /api/events/{id} - Stub até existir persistência
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        try {
            eventService.delete(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
        }
    }

    // ======= Validações básicas do POJO =======
    private List<String> validate(Event e) {
        List<String> errors = new ArrayList<>();

        if (e.getEvent_name() == null || e.getEvent_name().isBlank()) {
            errors.add("Nome do evento não pode ser vazio");
        }
        if (e.getIs_EAD() == null) {
            errors.add("Campo is_EAD deve ser true/false");
        }
        if (Boolean.FALSE.equals(e.getIs_EAD())) {
            if (e.getAddress() == null || e.getAddress().isBlank()) {
                errors.add("Endereço é obrigatório para evento presencial");
            }
        }
        if (e.getEvent_date() == null) {
            errors.add("Data do evento é obrigatória");
        }
        if (e.getBuy_time_limit() != null && e.getEvent_date() != null
                && e.getBuy_time_limit().isAfter(e.getEvent_date())) {
            errors.add("Data limite de compra não pode ser após a data do evento");
        }
        if (e.getLot_quantity() != null && e.getLot_quantity() < 0) {
            errors.add("Quantidade de lotes não pode ser negativa");
        }
        if (e.getQuantity() != null && e.getQuantity() < 0) {
            errors.add("Quantidade de ingressos não pode ser negativa");
        }
        if (e.getPresenters() == null) {
            errors.add("Lista de apresentadores não pode ser nula (pode ser vazia)");
        }
        return errors;
    }
}
