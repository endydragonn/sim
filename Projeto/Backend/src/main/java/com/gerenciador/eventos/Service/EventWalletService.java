package com.gerenciador.eventos.Service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.gerenciador.eventos.POJO.Event;
import com.gerenciador.eventos.POJO.EventWallet;
import com.gerenciador.eventos.POJO.MyWallet;
import com.gerenciador.eventos.Repository.EventRepository;
import com.gerenciador.eventos.Repository.EventWalletRepository;
import com.gerenciador.eventos.Repository.MyWalletRepository;

@Service
public class EventWalletService {

    @Autowired
    private EventWalletRepository eventWalletRepository;
    @Autowired
    private MyWalletRepository myWalletRepository;
    @Autowired
    private EventRepository eventRepository;

    public EventWallet addLink(EventWallet ew) {
        validateBasic(ew);
        // existência
        MyWallet wallet = myWalletRepository.findByUserId(ew.getUserId());
        if (wallet == null) throw new IllegalArgumentException("Carteira do usuário não encontrada");
        Event event = eventRepository.findById(ew.getEventId());
        if (event == null) throw new IllegalArgumentException("Evento não encontrado");
        // duplicidade
        if (eventWalletRepository.exists(ew.getUserId(), ew.getEventId()))
            throw new IllegalArgumentException("Vínculo já existente");

        return eventWalletRepository.save(ew);
    }

    public void removeLink(Long userId, Long eventId) {
        if (userId == null || userId <= 0) throw new IllegalArgumentException("userId inválido");
        if (eventId == null || eventId <= 0) throw new IllegalArgumentException("eventId inválido");
        eventWalletRepository.delete(userId, eventId);
    }

    public List<EventWallet> listByUser(Long userId) {
        if (userId == null || userId <= 0) throw new IllegalArgumentException("userId inválido");
        return eventWalletRepository.findAllByUserId(userId);
    }

    public String getValidationErrors(EventWallet ew) {
        StringBuilder sb = new StringBuilder();
        if (ew.getUserId() == null || ew.getUserId() <= 0) sb.append("user_id é obrigatório e deve ser positivo. ");
        if (ew.getEventId() == null || ew.getEventId() <= 0) sb.append("event_id é obrigatório e deve ser positivo. ");
        if (ew.getUserId() != null && ew.getUserId() > 0) {
            if (myWalletRepository.findByUserId(ew.getUserId()) == null) sb.append("Carteira não encontrada. ");
        }
        if (ew.getEventId() != null && ew.getEventId() > 0) {
            if (eventRepository.findById(ew.getEventId()) == null) sb.append("Evento não encontrado. ");
        }
        if (ew.getUserId() != null && ew.getEventId() != null
            && ew.getUserId() > 0 && ew.getEventId() > 0
            && eventWalletRepository.exists(ew.getUserId(), ew.getEventId())) {
            sb.append("Vínculo já existente. ");
        }
        return sb.toString().trim();
    }

    private void validateBasic(EventWallet ew) {
        if (ew.getUserId() == null || ew.getUserId() <= 0)
            throw new IllegalArgumentException("user_id é obrigatório e deve ser positivo");
        if (ew.getEventId() == null || ew.getEventId() <= 0)
            throw new IllegalArgumentException("event_id é obrigatório e deve ser positivo");
    }
}
