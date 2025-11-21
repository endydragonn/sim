package com.gerenciador.eventos.bff;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.gerenciador.eventos.POJO.Event;
import com.gerenciador.eventos.POJO.EventWallet;
import com.gerenciador.eventos.POJO.MyWallet;
import com.gerenciador.eventos.POJO.User;
import com.gerenciador.eventos.Service.EventService;
import com.gerenciador.eventos.Service.EventWalletService;
import com.gerenciador.eventos.Service.MyWalletService;
import com.gerenciador.eventos.Service.UserService;

// Scan for packages as per structure
@SpringBootApplication
@ComponentScan(basePackages = {"com.gerenciador.eventos"})
public class BffApplication {

    public static void main(String[] args) {
        SpringApplication.run(BffApplication.class, args);
    }

    // User BFF Controller (adapted from provided)
    @RestController
    @RequestMapping("/bff/users")
    public static class UserBffController {
        private final UserService userService;
        private final com.gerenciador.eventos.security.JwtUtil jwtUtil;

        public UserBffController(UserService userService, com.gerenciador.eventos.security.JwtUtil jwtUtil) {
            this.userService = userService;
            this.jwtUtil = jwtUtil;
        }

        @PostMapping
        public ResponseEntity<?> createUser(@RequestBody User user) {
            try {
                User created = userService.createUser(user);
                return ResponseEntity.status(HttpStatus.CREATED).body(created);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(e.getMessage());
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erro ao criar usuário: " + e.getMessage());
            }
        }

        @GetMapping("/{id}")
        public ResponseEntity<?> getUserById(@PathVariable Long id) {
            try {
                User user = userService.findById(id);
                return ResponseEntity.ok(user);
            } catch (RuntimeException e) {
                return ResponseEntity.notFound().build();
            }
        }

        @GetMapping("/email/{email}")
        public ResponseEntity<?> getUserByEmail(@PathVariable String email) {
            try {
                User user = userService.findByEmail(email);
                return ResponseEntity.ok(user);
            } catch (RuntimeException e) {
                return ResponseEntity.notFound().build();
            }
        }

        @PutMapping("/{id}")
        public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User user) {
            try {
                user.setId(id);
                User updated = userService.updateUser(user);
                return ResponseEntity.ok(updated);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(e.getMessage());
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erro ao atualizar usuário: " + e.getMessage());
            }
        }

        @PutMapping("/{id}/password")
        public ResponseEntity<?> changePassword(@PathVariable Long id, @RequestBody java.util.Map<String, String> passwords) {
            try {
                String oldPassword = passwords.get("oldPassword");
                String newPassword = passwords.get("newPassword");
                
                if (oldPassword == null || oldPassword.isEmpty()) {
                    return ResponseEntity.badRequest().body("Senha atual é obrigatória");
                }
                if (newPassword == null || newPassword.isEmpty()) {
                    return ResponseEntity.badRequest().body("Nova senha é obrigatória");
                }
                
                boolean success = userService.changePassword(id, oldPassword, newPassword);
                if (success) {
                    return ResponseEntity.ok("Senha alterada com sucesso");
                } else {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erro ao alterar senha");
                }
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body(e.getMessage());
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erro ao alterar senha: " + e.getMessage());
            }
        }

        @DeleteMapping("/{id}")
        public ResponseEntity<?> deleteUser(@PathVariable Long id) {
            try {
                userService.deactivateUser(id);
                return ResponseEntity.noContent().build();
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erro ao deletar usuário: " + e.getMessage());
            }
        }

        @PostMapping("/validate")
        public ResponseEntity<?> validateUser(@RequestBody User user) {
            String errors = userService.getValidationErrors(user);
            if (errors.isEmpty()) {
                return ResponseEntity.ok("Usuário válido");
            } else {
                return ResponseEntity.badRequest().body(errors);
            }
        }

        @PostMapping("/login")
        public ResponseEntity<?> login(@RequestBody User loginRequest) {
            User user = userService.login(loginRequest.getEmail(), loginRequest.getPassword());
            if (user != null) {
                // Gerar token JWT (injeção manual simples)
                String token = jwtUtil.generateToken(user.getEmail());
                java.util.Map<String, Object> body = new java.util.HashMap<>();
                body.put("user", user);
                body.put("token", token);
                return ResponseEntity.ok(body);
            }
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Credenciais inválidas");
        }

        @GetMapping("/me")
        public ResponseEntity<?> getCurrentUser() {
            try {
                // O email vem do SecurityContext populado pelo JwtAuthenticationFilter
                org.springframework.security.core.Authentication auth = 
                    org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
                
                if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getPrincipal())) {
                    String email = auth.getName(); // Email do subject do JWT
                    User user = userService.findByEmail(email);
                    if (user != null) {
                        return ResponseEntity.ok(user);
                    }
                }
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Não autenticado");
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro ao buscar usuário: " + e.getMessage());
            }
        }
    }

    // Event BFF Controller (adapted from provided)
    @RestController
    @RequestMapping("/bff/events")
    public static class EventBffController {
        private final EventService eventService;

        public EventBffController(EventService eventService) {
            this.eventService = eventService;
        }

        @PostMapping
        public ResponseEntity<?> createEvent(@RequestBody Event event) {
            List<String> basicErrors = validateEventBasic(event);
            if (!basicErrors.isEmpty()) {
                return ResponseEntity.badRequest().body(String.join("; ", basicErrors));
            }
            try {
                Event saved = eventService.createEvent(event);
                return ResponseEntity.status(HttpStatus.CREATED).body(saved);
            } catch (IllegalArgumentException ex) {
                return ResponseEntity.badRequest().body(ex.getMessage());
            } catch (RuntimeException ex) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
            }
        }

        @PostMapping("/validate")
        public ResponseEntity<?> validateEvent(@RequestBody Event event) {
            List<String> errors = validateEventBasic(event);
            String serviceErrors = eventService.getValidationErrors(event);
            if (!serviceErrors.isBlank()) {
                errors.add(serviceErrors);
            }
            if (errors.isEmpty()) {
                return ResponseEntity.ok("Evento válido");
            }
            return ResponseEntity.badRequest().body(String.join("; ", errors));
        }

        @GetMapping("/{id}")
        public ResponseEntity<?> getEventById(@PathVariable Long id) {
            try {
                Event event = eventService.findById(id);
                return ResponseEntity.ok(event);
            } catch (RuntimeException ex) {
                return ResponseEntity.notFound().build();
            }
        }

        @PutMapping("/{id}")
        public ResponseEntity<?> updateEvent(@PathVariable Long id, @RequestBody Event event) {
            if (event.getEvent_id() == null) {
                event.setEvent_id(id);
            } else if (!id.equals(event.getEvent_id())) {
                return ResponseEntity.badRequest().body("ID do path difere do body");
            }
            List<String> basicErrors = validateEventBasic(event);
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

        @DeleteMapping("/{id}")
        public ResponseEntity<?> deleteEvent(@PathVariable Long id) {
            try {
                eventService.delete(id);
                return ResponseEntity.noContent().build();
            } catch (RuntimeException ex) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
            }
        }

        @GetMapping("/search")
        public ResponseEntity<List<Event>> searchEvents(@RequestParam String term) {
            return ResponseEntity.ok(eventService.searchEvents(term));
        }

        @GetMapping
        public ResponseEntity<List<Event>> getEventsByCreator(@RequestParam(required = false) Long creator_id) {
            if (creator_id == null) {
                return ResponseEntity.badRequest().build();
            }
            try {
                List<Event> events = eventService.findByCreatorId(creator_id);
                return ResponseEntity.ok(events);
            } catch (RuntimeException ex) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
            }
        }

        @PostMapping(value = "/{id}/image", consumes = "multipart/form-data")
        public ResponseEntity<?> uploadEventImage(
                @PathVariable Long id,
                @RequestParam("image") org.springframework.web.multipart.MultipartFile file) {
            try {
                // Validar tamanho do arquivo (max 5MB)
                if (file.getSize() > 5 * 1024 * 1024) {
                    return ResponseEntity.badRequest().body("Imagem muito grande. Tamanho máximo: 5MB");
                }

                // Validar tipo do arquivo
                String contentType = file.getContentType();
                if (contentType == null || !contentType.startsWith("image/")) {
                    return ResponseEntity.badRequest().body("Arquivo deve ser uma imagem");
                }

                // Ler e converter para JPG
                byte[] imageBytes = convertToJpg(file.getBytes(), file.getContentType());

                // Buscar evento e atualizar imagem
                Event event = eventService.findById(id);
                event.setImage_data(imageBytes);
                eventService.updateEvent(event);

                return ResponseEntity.ok("Imagem carregada com sucesso");
            } catch (RuntimeException ex) {
                return ResponseEntity.notFound().build();
            } catch (Exception ex) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body("Erro ao carregar imagem: " + ex.getMessage());
            }
        }

        @GetMapping("/{id}/image")
        public ResponseEntity<byte[]> getEventImage(@PathVariable Long id) {
            try {
                Event event = eventService.findById(id);
                byte[] imageData = event.getImage_data();
                
                if (imageData == null || imageData.length == 0) {
                    return ResponseEntity.notFound().build();
                }

                return ResponseEntity.ok()
                        .header("Content-Type", "image/jpeg")
                        .header("Cache-Control", "max-age=3600")
                        .body(imageData);
            } catch (RuntimeException ex) {
                return ResponseEntity.notFound().build();
            }
        }

        private byte[] convertToJpg(byte[] inputBytes, String contentType) throws Exception {
            java.io.ByteArrayInputStream bais = new java.io.ByteArrayInputStream(inputBytes);
            java.awt.image.BufferedImage image = javax.imageio.ImageIO.read(bais);
            
            if (image == null) {
                throw new IllegalArgumentException("Não foi possível ler a imagem");
            }

            // Converter para RGB se necessário (remover alpha channel)
            java.awt.image.BufferedImage rgbImage = new java.awt.image.BufferedImage(
                    image.getWidth(), image.getHeight(), java.awt.image.BufferedImage.TYPE_INT_RGB);
            rgbImage.createGraphics().drawImage(image, 0, 0, java.awt.Color.WHITE, null);

            // Escrever como JPG com compressão
            java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
            javax.imageio.ImageWriteParam jpgWriteParam = javax.imageio.ImageIO
                    .getImageWritersByFormatName("jpg").next().getDefaultWriteParam();
            jpgWriteParam.setCompressionMode(javax.imageio.ImageWriteParam.MODE_EXPLICIT);
            jpgWriteParam.setCompressionQuality(0.85f);

            javax.imageio.ImageWriter writer = javax.imageio.ImageIO.getImageWritersByFormatName("jpg").next();
            writer.setOutput(new javax.imageio.stream.MemoryCacheImageOutputStream(baos));
            writer.write(null, new javax.imageio.IIOImage(rgbImage, null, null), jpgWriteParam);
            writer.dispose();

            return baos.toByteArray();
        }

        private List<String> validateEventBasic(Event e) {
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
            if (e.getQuantity() < 0) {
                errors.add("Quantidade de ingressos não pode ser negativa");
            }
            if (e.getPresenters() == null) {
                errors.add("Lista de apresentadores não pode ser nula (pode ser vazia)");
            }
            return errors;
        }
    }

    // EventWallet BFF Controller (adapted from provided)
    @RestController
    @RequestMapping("/bff/event-wallets")
    public static class EventWalletBffController {
        private final EventWalletService eventWalletService;

        public EventWalletBffController(EventWalletService eventWalletService) {
            this.eventWalletService = eventWalletService;
        }

        @PostMapping
        public ResponseEntity<?> addLink(@RequestBody EventWallet ew) {
            List<String> errors = validateEventWalletBasic(ew);
            if (!errors.isEmpty()) {
                return ResponseEntity.badRequest().body(String.join("; ", errors));
            }
            try {
                EventWallet saved = eventWalletService.addLink(ew);
                return ResponseEntity.status(HttpStatus.CREATED).body(saved);
            } catch (IllegalArgumentException ex) {
                return ResponseEntity.badRequest().body(ex.getMessage());
            } catch (RuntimeException ex) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ex.getMessage());
            }
        }

        @PostMapping("/validate")
        public ResponseEntity<?> validateLink(@RequestBody EventWallet ew) {
            List<String> errors = validateEventWalletBasic(ew);
            String serviceErrors = eventWalletService.getValidationErrors(ew);
            if (!serviceErrors.isBlank()) {
                errors.add(serviceErrors);
            }
            if (errors.isEmpty()) {
                return ResponseEntity.ok("Vínculo válido");
            }
            return ResponseEntity.badRequest().body(String.join("; ", errors));
        }

        @DeleteMapping
        public ResponseEntity<Void> removeLink(@RequestParam Long userId, @RequestParam Long eventId) {
            eventWalletService.removeLink(userId, eventId);
            return ResponseEntity.ok().build();
        }

        @GetMapping("/user/{userId}")
        public ResponseEntity<List<EventWallet>> listByUser(@PathVariable Long userId) {
            return ResponseEntity.ok(eventWalletService.listByUser(userId));
        }

        private List<String> validateEventWalletBasic(EventWallet ew) {
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

    // MyWallet BFF Controller (adapted from provided)
    @RestController
    @RequestMapping("/bff/my-wallets")
    public static class MyWalletBffController {
        private final MyWalletService myWalletService;

        public MyWalletBffController(MyWalletService myWalletService) {
            this.myWalletService = myWalletService;
        }

        @PostMapping("/validate")
        public ResponseEntity<?> validateWallet(@RequestBody MyWallet wallet) {
            List<String> errors = validateMyWalletBasic(wallet);
            if (errors.isEmpty()) {
                return ResponseEntity.ok("Carteira válida");
            }
            return ResponseEntity.badRequest().body(String.join("; ", errors));
        }

        @GetMapping("/{userId}")
        public ResponseEntity<?> getByUser(@PathVariable Long userId) {
            if (userId == null || userId <= 0) {
                return ResponseEntity.badRequest().body("userId inválido");
            }
            MyWallet wallet = myWalletService.getByUserId(userId);
            return ResponseEntity.ok(wallet);
        }

        @PostMapping("/ensure/{userId}")
        public ResponseEntity<MyWallet> ensureExists(@PathVariable Long userId) {
            return ResponseEntity.ok(myWalletService.ensureExists(userId));
        }

        private List<String> validateMyWalletBasic(MyWallet w) {
            List<String> errors = new ArrayList<>();
            if (w.getUserId() == null || w.getUserId() <= 0) {
                errors.add("user_id é obrigatório e deve ser positivo");
            }
            return errors;
        }
    }
}
