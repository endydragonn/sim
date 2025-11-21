package com.gerenciador.eventos;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

import com.gerenciador.eventos.POJO.Event;
import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Service.EventService;
import com.gerenciador.eventos.Service.UserService;
import com.gerenciador.eventos.TestSupport.GlobalDbTruncator;

@SpringBootTest
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Import(GlobalDbTruncator.class)
public class EventTest {

    @Autowired
    private UserService userService;

    @Autowired
    private EventService eventService;

    // Limpeza suite-level via GlobalDbTruncator

    @Test
    public void testCreateEventWithDefaults() {
        // 1) Criar usuário criador
        User creator = new User();
        creator.setName("Creator");
        creator.setEmail("creator@example.com");
        creator = userService.createUser(creator);
        assertNotNull(creator.getId());

        // 2) Criar evento com buy_time_limit nulo -> deve assumir event_date
        Event e = new Event();
        e.setCreator_id(creator.getId());
        e.setEvent_name("Evento X");
        e.setIs_EAD(true); // EAD, logo address opcional
        LocalDateTime eventDate = LocalDateTime.now().plusDays(30);
        e.setEvent_date(eventDate);
        e.setBuy_time_limit(null); // default aplicado no service
        e.setLot_quantity(null); // capacidade indefinida
        e.setQuantity(100);
        e.setDescription("desc");

        Event saved = eventService.createEvent(e);
        assertNotNull(saved.getEvent_id());
        assertEquals(eventDate, saved.getEvent_date());
        assertEquals(eventDate, saved.getBuy_time_limit(), "buy_time_limit deve assumir event_date quando nulo");
        assertNull(saved.getLot_quantity());
        assertNotNull(saved.getCreatedAt());
        assertNotNull(saved.getUpdatedAt());
    }
}
