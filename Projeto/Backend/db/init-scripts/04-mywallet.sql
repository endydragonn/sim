-- Table: public.mywallet
-- Tabela de carteiras (depende de users.user_id via FK)

DROP TABLE IF EXISTS public.mywallet CASCADE;

CREATE TABLE IF NOT EXISTS public.mywallet
(
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MyWallet_pkey" PRIMARY KEY (user_id),
    CONSTRAINT mywallet_user_id_fkey FOREIGN KEY (user_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mywallet
    OWNER to admin;

