package com.gerenciador.eventos.Service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.gerenciador.eventos.POJO.Event;
import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Repository.EventRepository;
import com.gerenciador.eventos.Repository.UserRepository;

/**
 * Service - regras de negócio e validações para Event
 */
@Service
public class EventService {

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private UserRepository userRepository;

    public Event createEvent(Event e) {
        // aplicar defaults dependentes de campos obrigatórios
        applyDefaults(e);
        validateRequired(e);
        validateRules(e);
        validateDuplicatesOnCreate(e);
        return eventRepository.save(e);
    }

    public Event updateEvent(Event e) {
        if (e.getEvent_id() == null) {
            throw new IllegalArgumentException("event_id é obrigatório");
        }
        // não forçamos default em update; somente validações
        validateRequired(e);
        validateRules(e);
        validateDuplicatesOnUpdate(e);
        return eventRepository.update(e);
    }

    public Event findById(Long id) {
        Event e = eventRepository.findById(id);
        if (e == null) throw new RuntimeException("Evento não encontrado: id=" + id);
        return e;
    }

    public Event findByName(String name) {
        Event e = eventRepository.findByName(name);
        if (e == null) throw new RuntimeException("Evento não encontrado: name=" + name);
        return e;
    }

    public void delete(Long id) {
        eventRepository.delete(id);
    }

    public boolean canBeCreated(Event e) {
        try {
            applyDefaults(e);
            validateRequired(e);
            validateRules(e);
            validateDuplicatesOnCreate(e);
            return true;
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }

    public String getValidationErrors(Event e) {
        StringBuilder sb = new StringBuilder();
        // aplicar defaults antes de validar
        applyDefaults(e);
        if (e.getCreator_id() == null) sb.append("creator_id é obrigatório. ");
        if (e.getEvent_name() == null || e.getEvent_name().isBlank()) sb.append("Nome do evento é obrigatório. ");
        if (e.getIs_EAD() == null) sb.append("is_EAD deve ser true/false. ");
        if (Boolean.FALSE.equals(e.getIs_EAD())) {
            if (e.getAddress() == null || e.getAddress().isBlank()) sb.append("Endereço é obrigatório para presencial. ");
        }
        if (e.getEvent_date() == null) sb.append("Data do evento é obrigatória. ");
        if (e.getBuy_time_limit() != null && e.getEvent_date() != null && e.getBuy_time_limit().isAfter(e.getEvent_date()))
            sb.append("buy_time_limit não pode ser após event_date. ");
        if (e.getLot_quantity() != null && e.getLot_quantity() < 0) sb.append("capacity (lot_quantity) não pode ser negativa. ");
        if (e.getQuantity() < 0) sb.append("quant (quantity) não pode ser negativo. ");
        // unicidade do nome
        if (e.getEvent_name() != null && !e.getEvent_name().isBlank() && eventRepository.nameExists(e.getEvent_name())) {
            sb.append("Nome de evento já existente: ").append(e.getEvent_name()).append(". ");
        }
        // criador existente
        if (e.getCreator_id() != null) {
            User u = userRepository.findById(e.getCreator_id());
            if (u == null) sb.append("creator_id não existe em users. ");
        }
        return sb.toString().trim();
    }

    // ======= validações privadas =======
    private void validateRequired(Event e) {
        if (e.getCreator_id() == null) throw new IllegalArgumentException("creator_id é obrigatório");
        if (e.getEvent_name() == null || e.getEvent_name().isBlank()) throw new IllegalArgumentException("Nome do evento é obrigatório");
        if (e.getIs_EAD() == null) throw new IllegalArgumentException("is_EAD deve ser true/false");
        if (Boolean.FALSE.equals(e.getIs_EAD())) {
            if (e.getAddress() == null || e.getAddress().isBlank()) throw new IllegalArgumentException("Endereço é obrigatório para presencial");
        }
        if (e.getEvent_date() == null) throw new IllegalArgumentException("Data do evento é obrigatória");
    }

    private void validateRules(Event e) {
        if (e.getBuy_time_limit() != null && e.getEvent_date() != null && e.getBuy_time_limit().isAfter(e.getEvent_date()))
            throw new IllegalArgumentException("buy_time_limit não pode ser após event_date");
        if (e.getLot_quantity() != null && e.getLot_quantity() < 0)
            throw new IllegalArgumentException("capacity (lot_quantity) não pode ser negativa");
        if (e.getQuantity() < 0)
            throw new IllegalArgumentException("quant (quantity) não pode ser negativo");
        // valida existência do criador
        if (e.getCreator_id() != null) {
            User u = userRepository.findById(e.getCreator_id());
            if (u == null) throw new IllegalArgumentException("creator_id não existe");
        }
    }

    // Defaults de domínio aplicados no POJO (sem depender do banco)
    private void applyDefaults(Event e) {
        // Se buy_time_limit vier nulo, usar event_date (quando disponível)
        if (e != null && e.getBuy_time_limit() == null && e.getEvent_date() != null) {
            e.setBuy_time_limit(e.getEvent_date());
        }
    }

    private void validateDuplicatesOnCreate(Event e) {
        if (e.getEvent_name() != null && !e.getEvent_name().isBlank() && eventRepository.nameExists(e.getEvent_name()))
            throw new IllegalArgumentException("Nome de evento já existente: " + e.getEvent_name());
    }

    private void validateDuplicatesOnUpdate(Event e) {
        if (e.getEvent_name() != null && !e.getEvent_name().isBlank()) {
            Event existing = eventRepository.findByName(e.getEvent_name());
            if (existing != null && !existing.getEvent_id().equals(e.getEvent_id())) {
                throw new IllegalArgumentException("Nome de evento já existente: " + e.getEvent_name());
            }
        }
    }

    public List<Event> searchEvents(String term) {
        // If no term provided, return all events
        List<Event> all = eventRepository.findAll();
        if (term == null || term.isBlank()) {
            return all;
        }

        String q = term.toLowerCase();
        List<Event> result = new ArrayList<>();
        for (Event e : all) {
            if (e.getEvent_name() != null && e.getEvent_name().toLowerCase().contains(q)) {
                result.add(e);
            }
        }
        return result;
    }

    public List<Event> findByCreatorId(Long creatorId) {
        if (creatorId == null) {
            return new ArrayList<>();
        }
        
        List<Event> all = eventRepository.findAll();
        List<Event> result = new ArrayList<>();
        for (Event e : all) {
            if (e.getCreator_id() != null && e.getCreator_id().equals(creatorId)) {
                result.add(e);
            }
        }
        return result;
    }
}
