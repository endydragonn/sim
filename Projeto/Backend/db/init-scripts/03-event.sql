-- Table: public.event
-- Tabela de eventos (depende de users.user_id via FK)
-- Encoding: UTF-8

SET client_encoding = 'UTF8';

DROP TABLE IF EXISTS public.event CASCADE;

CREATE TABLE IF NOT EXISTS public.event
(
    event_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    creator_id integer NOT NULL,
    event_name text COLLATE pg_catalog."default" NOT NULL,
    ead boolean NOT NULL DEFAULT false,
    address text COLLATE pg_catalog."default",
    event_date timestamp without time zone NOT NULL,
    buy_time_limit timestamp without time zone NOT NULL,
    capacity integer,
    quant integer NOT NULL,
    description text COLLATE pg_catalog."default" NOT NULL,
    image_data bytea,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Event_pkey" PRIMARY KEY (event_id),
    CONSTRAINT "Event_event_name_key" UNIQUE (event_name),
    CONSTRAINT "Event_creator_id_fkey" FOREIGN KEY (creator_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.event
    OWNER to admin;

