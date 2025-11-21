package com.gerenciador.eventos;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

import com.gerenciador.eventos.POJO.Event;
import com.gerenciador.eventos.POJO.EventWallet;
import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Service.EventService;
import com.gerenciador.eventos.Service.EventWalletService;
import com.gerenciador.eventos.Service.MyWalletService;
import com.gerenciador.eventos.Service.UserService;
import com.gerenciador.eventos.TestSupport.GlobalDbTruncator;

@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Import(GlobalDbTruncator.class)
public class EventWalletTest {

    @Autowired
    private UserService userService;

    @Autowired
    private MyWalletService myWalletService;

    @Autowired
    private EventService eventService;

    @Autowired
    private EventWalletService eventWalletService;

    // Limpeza suite-level via GlobalDbTruncator

    @Test
    public void testAddEventToWallet() {
        // 1) user + wallet
        User u = new User();
        u.setName("Wallet Owner");
        u.setEmail("owner@example.com");
        u = userService.createUser(u);
        assertNotNull(u.getId());
        myWalletService.ensureExists(u.getId()); // idempotente

        // 2) event
        Event e = new Event();
        e.setCreator_id(u.getId());
        e.setEvent_name("Evento Wallet");
        e.setIs_EAD(true);
        LocalDateTime eventDate = LocalDateTime.now().plusDays(10);
        e.setEvent_date(eventDate);
        e.setBuy_time_limit(null); // defaultará para event_date
        e.setQuantity(10);
        e.setDescription("desc");
        e = eventService.createEvent(e);
        assertNotNull(e.getEvent_id());

        // 3) link
        EventWallet link = new EventWallet(u.getId(), e.getEvent_id());
        EventWallet saved = eventWalletService.addLink(link);
        assertNotNull(saved);
        assertEquals(u.getId(), saved.getUserId());
        assertEquals(e.getEvent_id(), saved.getEventId());

        // 4) duplicated must fail
        final Long uid = u.getId();
        final Long eid = e.getEvent_id();
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            eventWalletService.addLink(new EventWallet(uid, eid));
        });
        assertTrue(ex.getMessage().contains("Vínculo já existente"));
    }
}
