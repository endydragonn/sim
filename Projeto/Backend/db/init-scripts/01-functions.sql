-- FUNCTION: public.create_wallet_for_user()
-- Esta função é usada pelo trigger em Users para criar automaticamente uma carteira

DROP FUNCTION IF EXISTS public.create_wallet_for_user();

CREATE OR REPLACE FUNCTION public.create_wallet_for_user()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    INSERT INTO public.MyWallet (user_id)
    VALUES (NEW.user_id);
    RETURN NEW;
END;
$BODY$;

ALTER FUNCTION public.create_wallet_for_user()
    OWNER TO admin;

