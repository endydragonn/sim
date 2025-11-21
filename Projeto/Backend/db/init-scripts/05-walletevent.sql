-- Table: public.walletevent

-- DROP TABLE IF EXISTS public.walletevent;

CREATE TABLE IF NOT EXISTS public.walletevent
(
    user_id integer NOT NULL,
    event_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "WalletEvent_pkey" PRIMARY KEY (user_id, event_id),
    CONSTRAINT "WalletEvent_event_id_fkey" FOREIGN KEY (event_id)
        REFERENCES public.event (event_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE RESTRICT,
    CONSTRAINT "WalletEvent_user_id_fkey" FOREIGN KEY (user_id)
        REFERENCES public.users (user_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.walletevent
    OWNER to admin;
