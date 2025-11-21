-- Table: public.users
-- Tabela principal de usuários (deve ser criada antes de Event e MyWallet pois ambas referenciam user_id)

DROP TABLE IF EXISTS public.users CASCADE;

CREATE TABLE IF NOT EXISTS public.users
(
    user_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    user_name text COLLATE pg_catalog."default" NOT NULL,
    email text COLLATE pg_catalog."default" NOT NULL,
    fone text COLLATE pg_catalog."default" NOT NULL,
    password text COLLATE pg_catalog."default" NOT NULL,
    birthdate date NOT NULL,
    admin boolean NOT NULL DEFAULT false,
    isActive boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "User_id" PRIMARY KEY (user_id),
    CONSTRAINT "Users_email_key" UNIQUE (email),
    CONSTRAINT "Users_fone_key" UNIQUE (fone),
    CONSTRAINT "Users_user_name_key" UNIQUE (user_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.users
    OWNER to admin;

-- Trigger: trigger_create_wallet
-- Este trigger chama a função create_wallet_for_user após inserção de um novo usuário

DROP TRIGGER IF EXISTS trigger_create_wallet ON public.users;

CREATE OR REPLACE TRIGGER trigger_create_wallet
    AFTER INSERT
    ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_wallet_for_user();
