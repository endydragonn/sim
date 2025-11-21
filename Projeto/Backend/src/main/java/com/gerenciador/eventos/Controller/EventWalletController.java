package com.gerenciador.eventos.Controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gerenciador.eventos.POJO.EventWallet;
import com.gerenciador.eventos.Service.EventWalletService;

/**
 * Controller REST para associação de eventos na carteira do usuário
 * (EventWallet). Sem persistência por enquanto.
 */
@RestController
@RequestMapping("/api/event-wallets")
public class EventWalletController {

    @Autowired
    private EventWalletService eventWalletService;

    /**
     * POST /api/event-wallets - Adicionar evento à carteira
     */
    @PostMapping
    public ResponseEntity<?> add(@RequestBody EventWallet ew) {
        List<String> errors = validate(ew);
        if (!errors.isEmpty()) {
            return ResponseEntity.badRequest().body(String.join("; ", errors));
        }
        EventWallet saved;
        try {
            saved = eventWalletService.addLink(ew);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(ex.getMessage());
        } catch (RuntimeException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    /**
     * POST /api/event-wallets/validate - Validar vínculo carteira-evento
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateLink(@RequestBody EventWallet ew) {
        List<String> errors = validate(ew);
        if (!errors.isEmpty()) {
            return ResponseEntity.badRequest().body(String.join("; ", errors));
        }
        String serviceErrors = eventWalletService.getValidationErrors(ew);
        if (!serviceErrors.isBlank()) {
            return ResponseEntity.badRequest().body(serviceErrors);
        }
        return ResponseEntity.ok("Vínculo válido");
    }

    private List<String> validate(EventWallet ew) {
        List<String> errors = new ArrayList<>();
        if (ew.getUserId() == null || ew.getUserId() <= 0) {
            errors.add("user_id é obrigatório e deve ser positivo");
        }
        if (ew.getEventId() == null || ew.getEventId() <= 0) {
            errors.add("event_id é obrigatório e deve ser positivo");
        }
        return errors;
    }
}
