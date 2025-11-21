-- 99-tests.sql
-- Suite de testes mínima para validar:
-- - Trigger que cria mywallet ao inserir em users
-- - Criação de eventos
-- - Relacionamento N:N em walletevent
-- - TRUNCATE e revalidação pós-TRUNCATE

\echo Iniciando testes mínimos do banco...

DO $$
DECLARE
  v_user1 integer;
  v_user2 integer;
  v_event1 integer;
  v_event2 integer;
  v_count integer;
  v_err   text;
BEGIN
  v_err := NULL;
  BEGIN
    -- Zerar estado antes dos testes, garantindo baseline limpa
    TRUNCATE TABLE public.event, public.walletevent, public.mywallet, public.users RESTART IDENTITY CASCADE;

    -- 1) Inserir usuário e validar trigger da carteira
    INSERT INTO public.users (user_name, email, fone, password, birthdate)
    VALUES ('teste_trigger', 'trigger@test.com', '5500000000', 'pw', '1990-01-01')
    RETURNING user_id INTO v_user1;

    SELECT count(*) INTO v_count FROM public.mywallet WHERE user_id = v_user1;
    IF v_count <> 1 THEN
      RAISE EXCEPTION 'Falha: trigger não criou mywallet (esperado 1, obtido %)', v_count;
    END IF;

    -- 2) Criar eventos
    INSERT INTO public.event (creator_id, event_name, event_date, buy_time_limit, quant, description)
    VALUES (v_user1, 'Evento Teste 1', now() + interval '30 days', now() + interval '20 days', 100, 'desc1')
    RETURNING event_id INTO v_event1;

    INSERT INTO public.event (creator_id, event_name, event_date, buy_time_limit, quant, description)
    VALUES (v_user1, 'Evento Teste 2', now() + interval '60 days', now() + interval '50 days', 50, 'desc2')
    RETURNING event_id INTO v_event2;

    -- 3) Validar N:N em walletevent
    INSERT INTO public.users (user_name, email, fone, password, birthdate)
    VALUES ('teste_trigger2', 'trigger2@test.com', '6600000000', 'pw', '1992-02-02')
    RETURNING user_id INTO v_user2;

    -- mywallet deve existir para v_user2 via trigger
    SELECT count(*) INTO v_count FROM public.mywallet WHERE user_id = v_user2;
    IF v_count <> 1 THEN
      RAISE EXCEPTION 'Falha: trigger não criou mywallet para segundo usuário (esperado 1, obtido %)', v_count;
    END IF;

    -- Inserir combinações N:N
    INSERT INTO public.walletevent (user_id, event_id) VALUES (v_user1, v_event1);
    INSERT INTO public.walletevent (user_id, event_id) VALUES (v_user2, v_event1);
    INSERT INTO public.walletevent (user_id, event_id) VALUES (v_user1, v_event2);

    SELECT count(*) INTO v_count FROM public.walletevent;
    IF v_count <> 3 THEN
      RAISE EXCEPTION 'Falha: esperado 3 registros em walletevent, obtido %', v_count;
    END IF;

    -- Tentar duplicado para validar PK composta (deve falhar com unique_violation)
    BEGIN
      INSERT INTO public.walletevent (user_id, event_id) VALUES (v_user1, v_event1);
      RAISE EXCEPTION 'Falha: inserção duplicada em walletevent não falhou como esperado';
    EXCEPTION WHEN unique_violation THEN
      -- OK, esperado
      NULL;
    END;

    -- 4) TRUNCATE e revalidação
    TRUNCATE TABLE public.event, public.walletevent, public.mywallet, public.users RESTART IDENTITY CASCADE;

    SELECT count(*) INTO v_count FROM public.users;      IF v_count <> 0 THEN RAISE EXCEPTION 'Falha: users não ficou vazio'; END IF;
    SELECT count(*) INTO v_count FROM public.mywallet;   IF v_count <> 0 THEN RAISE EXCEPTION 'Falha: mywallet não ficou vazio'; END IF;
    SELECT count(*) INTO v_count FROM public.event;      IF v_count <> 0 THEN RAISE EXCEPTION 'Falha: event não ficou vazio'; END IF;
    SELECT count(*) INTO v_count FROM public.walletevent;IF v_count <> 0 THEN RAISE EXCEPTION 'Falha: walletevent não ficou vazio'; END IF;

    -- 5) Inserir novo usuário após TRUNCATE para validar trigger novamente
    INSERT INTO public.users (user_name, email, fone, password, birthdate)
    VALUES ('teste_pos_truncate', 'postruncate@test.com', '7700000000', 'pw', '1995-05-05')
    RETURNING user_id INTO v_user1;

    SELECT count(*) INTO v_count FROM public.mywallet WHERE user_id = v_user1;
    IF v_count <> 1 THEN
      RAISE EXCEPTION 'Falha: trigger não criou mywallet após TRUNCATE (esperado 1, obtido %)', v_count;
    END IF;

    -- Limpar novamente, deixando banco vazio para uso
    TRUNCATE TABLE public.event, public.walletevent, public.mywallet, public.users RESTART IDENTITY CASCADE;
  EXCEPTION WHEN OTHERS THEN
    v_err := SQLERRM;
  END;

  -- Cleanup incondicional, independente de erros
  TRUNCATE TABLE public.event, public.walletevent, public.mywallet, public.users RESTART IDENTITY CASCADE;

  IF v_err IS NOT NULL THEN
    RAISE EXCEPTION 'Falha nos testes: %', v_err;
  ELSE
    RAISE NOTICE 'Testes mínimos concluídos com sucesso';
  END IF;
END$$;

\echo Testes concluídos.
