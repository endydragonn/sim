package com.gerenciador.eventos;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

import com.gerenciador.eventos.POJO.MyWallet;
import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Service.MyWalletService;
import com.gerenciador.eventos.Service.UserService;
import com.gerenciador.eventos.TestSupport.GlobalDbTruncator;

@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Import(GlobalDbTruncator.class)
public class MyWalletTest {

    @Autowired
    private UserService userService;

    @Autowired
    private MyWalletService myWalletService;

    // Limpeza suite-level via GlobalDbTruncator

    @Test
    public void testWalletExistsAfterUserCreation() {
        User u = new User();
        u.setName("Wallet User");
        u.setEmail("wallet@example.com");
        u = userService.createUser(u);
        assertNotNull(u.getId());

        // trigger deve criar; ensureExists garante idempotência
        myWalletService.ensureExists(u.getId());

        MyWallet w = myWalletService.getByUserId(u.getId());
        assertNotNull(w);
        assertEquals(u.getId(), w.getUserId());
    }
}
