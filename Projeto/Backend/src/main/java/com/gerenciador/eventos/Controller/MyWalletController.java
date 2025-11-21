package com.gerenciador.eventos.Controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gerenciador.eventos.POJO.MyWallet;
import com.gerenciador.eventos.Service.MyWalletService;

/**
 * Controller REST para MyWallet (carteira do usuário)
 * A carteira é criada automaticamente via trigger ao criar o usuário.
 * Portanto, não expomos criação manual; oferecemos consulta por userId.
 */
@RestController
@RequestMapping("/api/wallets")
public class MyWalletController {

    @Autowired
    private MyWalletService myWalletService;



    /**
     * POST /api/wallets/validate - Validar carteira
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateWallet(@RequestBody MyWallet wallet) {
        List<String> errors = validate(wallet);
        if (errors.isEmpty()) {
            return ResponseEntity.ok("Carteira válida");
        }
        return ResponseEntity.badRequest().body(String.join("; ", errors));
    }

    /**
     * GET /api/wallets/{userId} - Buscar carteira pelo ID do usuário
     */
    @GetMapping("/{userId}")
    public ResponseEntity<?> getByUser(@PathVariable Long userId) {
        if (userId == null || userId <= 0) {
            return ResponseEntity.badRequest().body("userId inválido");
        }
    MyWallet wallet = myWalletService.getByUserId(userId);
        return ResponseEntity.ok(wallet);
    }

    private List<String> validate(MyWallet w) {
        List<String> errors = new ArrayList<>();
        if (w.getUserId() == null || w.getUserId() <= 0) {
            errors.add("user_id é obrigatório e deve ser positivo");
        }
        return errors;
    }
}
