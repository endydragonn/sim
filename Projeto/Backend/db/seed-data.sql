-- ==========================================
-- SCRIPT PARA POPULAR TABELAS COM DADOS
-- Executa INSERTs sem limpar dados existentes
-- Encoding: UTF-8
-- ==========================================

SET client_encoding = 'UTF8';

-- Inserir usuários de exemplo
INSERT INTO users (user_name, email, fone, password, birthdate, admin) VALUES
    ('João Silva', 'joao.silva@email.com', '11987654321', 'senha123', '1990-05-15', false),
    ('Maria Santos', 'maria.santos@email.com', '11987654322', 'senha456', '1985-08-22', false),
    ('Pedro Oliveira', 'pedro.oliveira@email.com', '11987654323', 'senha789', '1992-03-10', false),
    ('Ana Costa', 'ana.costa@email.com', '11987654324', 'senha321', '1988-11-30', false),
    ('Carlos Souza', 'carlos.souza@email.com', '11987654325', 'senha654', '1995-07-18', true)
ON CONFLICT (email) DO NOTHING;

-- Inserir eventos de exemplo
INSERT INTO event (creator_id, event_name, ead, address, event_date, buy_time_limit, capacity, quant, description) VALUES
    (
        (SELECT user_id FROM users WHERE email = 'joao.silva@email.com'),
        'Workshop de Java',
        false,
        'Av. Paulista, 1000 - São Paulo, SP',
        '2025-12-15 09:00:00',
        '2025-12-14 23:59:59',
        100,
        2,
        'Aprenda Java do zero ao avançado com experts da área'
    ),
    (
        (SELECT user_id FROM users WHERE email = 'maria.santos@email.com'),
        'Conferência de DevOps',
        false,
        'Centro de Convenções - Rio de Janeiro, RJ',
        '2025-12-20 14:00:00',
        '2025-12-19 23:59:59',
        200,
        3,
        'As melhores práticas de DevOps e Cloud Computing'
    ),
    (
        (SELECT user_id FROM users WHERE email = 'pedro.oliveira@email.com'),
        'Hackathon 2025',
        false,
        'Campus UFMG - Belo Horizonte, MG',
        '2026-01-10 08:00:00',
        '2026-01-09 23:59:59',
        50,
        1,
        'Competição de programação com prêmios incríveis'
    ),
    (
        (SELECT user_id FROM users WHERE email = 'joao.silva@email.com'),
        'Meetup de Spring Boot',
        true,
        NULL,
        '2025-12-01 19:00:00',
        '2025-12-01 18:00:00',
        NULL,
        0,
        'Compartilhe experiências e aprenda sobre Spring Boot'
    ),
    (
        (SELECT user_id FROM users WHERE email = 'carlos.souza@email.com'),
        'Curso de Docker',
        false,
        'Rua XV de Novembro, 500 - Curitiba, PR',
        '2026-02-05 10:00:00',
        '2026-02-04 23:59:59',
        30,
        0,
        'Containerização e orquestração com Docker e Kubernetes'
    )
ON CONFLICT (event_name) DO NOTHING;

-- Nota: MyWallet é criada automaticamente pelo trigger create_wallet_for_user
-- quando um usuário é inserido, então não precisamos inserir aqui

-- Inserir inscrições em eventos (walletevent relaciona user_id com event_id)
INSERT INTO walletevent (user_id, event_id) VALUES
    (
        (SELECT user_id FROM users WHERE email = 'maria.santos@email.com'),
        (SELECT event_id FROM event WHERE event_name = 'Workshop de Java')
    ),
    (
        (SELECT user_id FROM users WHERE email = 'pedro.oliveira@email.com'),
        (SELECT event_id FROM event WHERE event_name = 'Conferência de DevOps')
    ),
    (
        (SELECT user_id FROM users WHERE email = 'ana.costa@email.com'),
        (SELECT event_id FROM event WHERE event_name = 'Meetup de Spring Boot')
    ),
    (
        (SELECT user_id FROM users WHERE email = 'carlos.souza@email.com'),
        (SELECT event_id FROM event WHERE event_name = 'Hackathon 2025')
    ),
    (
        (SELECT user_id FROM users WHERE email = 'maria.santos@email.com'),
        (SELECT event_id FROM event WHERE event_name = 'Curso de Docker')
    ),
    (
        (SELECT user_id FROM users WHERE email = 'joao.silva@email.com'),
        (SELECT event_id FROM event WHERE event_name = 'Conferência de DevOps')
    )
ON CONFLICT (user_id, event_id) DO NOTHING;

-- Exibir resumo dos dados inseridos
DO $$
DECLARE
    v_users_count INTEGER;
    v_events_count INTEGER;
    v_wallets_count INTEGER;
    v_transactions_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_users_count FROM users;
    SELECT COUNT(*) INTO v_events_count FROM event;
    SELECT COUNT(*) INTO v_wallets_count FROM mywallet;
    SELECT COUNT(*) INTO v_transactions_count FROM walletevent;
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE '✅ DADOS POPULADOS COM SUCESSO!';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '📊 Resumo:';
    RAISE NOTICE '  • Usuários: %', v_users_count;
    RAISE NOTICE '  • Eventos: %', v_events_count;
    RAISE NOTICE '  • Carteiras: %', v_wallets_count;
    RAISE NOTICE '  • Transações: %', v_transactions_count;
    RAISE NOTICE '==========================================';
END $$;

-- Mostrar dados das tabelas
\echo ''
\echo '👥 ========== USUÁRIOS =========='
SELECT user_id, user_name, email, fone, TO_CHAR(birthdate, 'DD/MM/YYYY') as nascimento, admin
FROM users 
ORDER BY user_id;

\echo ''
\echo '🎫 ========== EVENTOS =========='
SELECT event_id, event_name, 
       CASE WHEN ead THEN 'EAD' ELSE 'Presencial' END as tipo,
       TO_CHAR(event_date, 'DD/MM/YYYY HH24:MI') as data_evento,
       capacity as capacidade, 
       quant as quantidade
FROM event 
ORDER BY event_date;

\echo ''
\echo '💰 ========== CARTEIRAS =========='
SELECT w.user_id, u.user_name as usuario
FROM mywallet w
JOIN users u ON w.user_id = u.user_id
ORDER BY w.user_id;

\echo ''
\echo '📝 ========== INSCRIÇÕES =========='
SELECT u.user_name as usuario, e.event_name as evento
FROM walletevent we
JOIN users u ON we.user_id = u.user_id
JOIN event e ON we.event_id = e.event_id
ORDER BY u.user_name, e.event_name;
