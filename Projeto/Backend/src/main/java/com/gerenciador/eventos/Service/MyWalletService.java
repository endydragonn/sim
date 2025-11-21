package com.gerenciador.eventos.Service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.gerenciador.eventos.POJO.MyWallet;
import com.gerenciador.eventos.Repository.MyWalletRepository;

@Service
public class MyWalletService {

    @Autowired
    private MyWalletRepository myWalletRepository;

    public MyWallet getByUserId(Long userId) {
        validateUserId(userId);
        MyWallet w = myWalletRepository.findByUserId(userId);
        if (w == null) throw new RuntimeException("Carteira não encontrada para user_id=" + userId);
        return w;
    }

    /** Idempotente: cria carteira se não existir (útil para consistência), mas em geral o trigger já cria */
    public MyWallet ensureExists(Long userId) {
        validateUserId(userId);
        return myWalletRepository.ensureExists(userId);
    }

    public boolean exists(Long userId) {
        validateUserId(userId);
        return myWalletRepository.existsByUserId(userId);
    }

    public String getValidationErrors(MyWallet w) {
        StringBuilder sb = new StringBuilder();
        if (w.getUserId() == null || w.getUserId() <= 0) sb.append("user_id é obrigatório e deve ser positivo. ");
        return sb.toString().trim();
    }

    private void validateUserId(Long userId) {
        if (userId == null || userId <= 0) throw new IllegalArgumentException("userId inválido");
    }
}
