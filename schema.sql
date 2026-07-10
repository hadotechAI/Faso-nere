--
-- PostgreSQL database dump
--

\restrict RvbIN5NCBCdAQeJ5cGfcxjJUrCNQjiHGPDByNTHrokqs0L6mTsJUPMmbj6KUrEG

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: audit_action; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.audit_action AS ENUM (
    'inscription',
    'login',
    'logout',
    'verification_otp',
    'achat_pack',
    'tirage',
    'depot',
    'retrait',
    'modification_profil',
    'suspension_compte',
    'activation_compte',
    'ajustement_admin',
    'modif_cadeau',
    'modif_lot',
    'notification_admin'
);


ALTER TYPE public.audit_action OWNER TO postgres;

--
-- Name: gift_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gift_category AS ENUM (
    'terrain',
    'ciment',
    'materiaux',
    'aucun'
);


ALTER TYPE public.gift_category OWNER TO postgres;

--
-- Name: livraison_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.livraison_status AS ENUM (
    'en_attente',
    'contacte',
    'en_cours',
    'livre',
    'annule'
);


ALTER TYPE public.livraison_status OWNER TO postgres;

--
-- Name: mouvement_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.mouvement_type AS ENUM (
    'depot',
    'retrait',
    'bonus_parrain',
    'remboursement',
    'ajustement_admin'
);


ALTER TYPE public.mouvement_type OWNER TO postgres;

--
-- Name: notif_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notif_type AS ENUM (
    'gain',
    'paiement',
    'parrainage',
    'livraison',
    'systeme',
    'promo'
);


ALTER TYPE public.notif_type OWNER TO postgres;

--
-- Name: otp_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.otp_type AS ENUM (
    'sms',
    'email'
);


ALTER TYPE public.otp_type OWNER TO postgres;

--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_method AS ENUM (
    'orange_money',
    'mtn_money',
    'moov_money',
    'carte_bancaire'
);


ALTER TYPE public.payment_method OWNER TO postgres;

--
-- Name: tirage_mode; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tirage_mode AS ENUM (
    'boites',
    'roue'
);


ALTER TYPE public.tirage_mode OWNER TO postgres;

--
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_status AS ENUM (
    'pending',
    'success',
    'failed',
    'cancelled',
    'refunded'
);


ALTER TYPE public.transaction_status OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'joueur',
    'admin',
    'super_admin'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: enregistrer_connexion(text, boolean, inet); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enregistrer_connexion(p_telephone text, p_succes boolean, p_ip inet DEFAULT NULL::inet) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_user         users%ROWTYPE;
  v_max_attempts INTEGER;
  v_lock_minutes INTEGER;
BEGIN
  SELECT * INTO v_user
  FROM users
  WHERE telephone = p_telephone AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN RETURN; END IF;

  SELECT valeur::integer INTO v_max_attempts
  FROM config_systeme WHERE cle = 'login_max_attempts';

  SELECT valeur::integer INTO v_lock_minutes
  FROM config_systeme WHERE cle = 'login_lock_duration_minutes';

  IF p_succes THEN
    UPDATE users SET
      failed_login_attempts = 0,
      locked_until          = NULL,
      last_login_at         = now(),
      last_login_ip         = p_ip
    WHERE id = v_user.id;

    INSERT INTO audit_logs (user_id, action, ip_address)
    VALUES (v_user.id, 'login', p_ip);

  ELSE
    UPDATE users SET
      failed_login_attempts = failed_login_attempts + 1,
      locked_until = CASE
        WHEN failed_login_attempts + 1 >= COALESCE(v_max_attempts, 5)
        THEN now() + (COALESCE(v_lock_minutes, 30)::text || ' minutes')::INTERVAL
        ELSE locked_until
      END
    WHERE id = v_user.id;
  END IF;
END;
$$;


ALTER FUNCTION public.enregistrer_connexion(p_telephone text, p_succes boolean, p_ip inet) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: tirages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tirages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    cadeau_id uuid NOT NULL,
    transaction_id uuid,
    mode public.tirage_mode DEFAULT 'boites'::public.tirage_mode NOT NULL,
    is_winner boolean DEFAULT false NOT NULL,
    valeur_gagnee integer DEFAULT 0 NOT NULL,
    statut_livraison public.livraison_status DEFAULT 'en_attente'::public.livraison_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_converted boolean DEFAULT false NOT NULL,
    CONSTRAINT tirages_valeur_gagnee_check CHECK ((valeur_gagnee >= 0))
);


ALTER TABLE public.tirages OWNER TO postgres;

--
-- Name: enregistrer_tirage(uuid, uuid, uuid, public.tirage_mode); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enregistrer_tirage(p_user_id uuid, p_lot_id uuid, p_cadeau_id uuid, p_mode public.tirage_mode) RETURNS public.tirages
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_cadeau      cadeaux%ROWTYPE;
  v_user        users%ROWTYPE;
  v_tirage      tirages%ROWTYPE;
  v_solde_avant INTEGER;
  v_solde_apres INTEGER;
  v_cout        INTEGER;
BEGIN
  SELECT * INTO v_cadeau
  FROM cadeaux WHERE id = p_cadeau_id AND lot_id = p_lot_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cadeau introuvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_user
  FROM users
  WHERE id = p_user_id
    AND is_active = true AND deleted_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Utilisateur introuvable' USING ERRCODE = 'P0003';
  END IF;

  IF v_user.tentatives <= 0 THEN
    RAISE EXCEPTION 'Pas assez de tentatives' USING ERRCODE = 'P0004';
  END IF;

  v_cout        := v_user.prix_par_tentative;
  v_solde_avant := v_user.solde;
  IF v_solde_avant < v_cout THEN
    RAISE EXCEPTION 'Solde insuffisant' USING ERRCODE = 'P0005';
  END IF;
  v_solde_apres := v_solde_avant - v_cout;

  INSERT INTO tirages
    (user_id, lot_id, cadeau_id, mode, is_winner, valeur_gagnee)
  VALUES
    (p_user_id, p_lot_id, p_cadeau_id, p_mode,
     v_cadeau.is_winner, v_cadeau.prix_reel)
  RETURNING * INTO v_tirage;

  UPDATE users SET
    tentatives = tentatives - 1,
    solde      = solde - v_cout,
    gagnes     = gagnes + CASE WHEN v_cadeau.is_winner THEN 1 ELSE 0 END
  WHERE id = p_user_id;

  IF v_cout > 0 THEN
    INSERT INTO mouvements_solde
      (user_id, type, montant, solde_avant, solde_apres, description)
    VALUES
      (p_user_id, 'retrait', -v_cout, v_solde_avant, v_solde_apres,
       'Tentative de tirage – ' || p_mode::text);
  END IF;

  IF v_cadeau.is_winner THEN
    INSERT INTO livraisons (tirage_id, user_id)
    VALUES (v_tirage.id, p_user_id)
    ON CONFLICT (tirage_id) DO NOTHING;
  END IF;

  INSERT INTO notifications (user_id, type, titre, message, metadata)
  VALUES (
    p_user_id,
    (CASE WHEN v_cadeau.is_winner THEN 'gain' ELSE 'systeme' END)::notif_type,
    CASE WHEN v_cadeau.is_winner THEN '🎉 Félicitations !' ELSE 'Tirage effectué' END,
    CASE WHEN v_cadeau.is_winner
      THEN 'Vous avez gagné : ' || v_cadeau.nom
      ELSE 'Pas de gain cette fois. Retentez votre chance !'
    END,
    jsonb_build_object(
      'tirage_id', v_tirage.id,
      'cadeau_id', p_cadeau_id,
      'is_winner', v_cadeau.is_winner,
      'cout',      v_cout
    )
  );

  INSERT INTO audit_logs (user_id, action, details)
  VALUES (
    p_user_id, 'tirage',
    jsonb_build_object(
      'tirage_id', v_tirage.id,
      'lot_id',    p_lot_id,
      'is_winner', v_cadeau.is_winner,
      'cout',      v_cout,
      'mode',      p_mode::text
    )
  );

  RETURN v_tirage;
END;
$$;


ALTER FUNCTION public.enregistrer_tirage(p_user_id uuid, p_lot_id uuid, p_cadeau_id uuid, p_mode public.tirage_mode) OWNER TO postgres;

--
-- Name: fn_set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_set_updated_at() OWNER TO postgres;

--
-- Name: fn_sync_nb_cadeaux(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sync_nb_cadeaux() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_lot_id UUID;
BEGIN
  v_lot_id := COALESCE(NEW.lot_id, OLD.lot_id);
  UPDATE lots
  SET nb_cadeaux = (
    SELECT COALESCE(SUM(quantite), 0)
    FROM cadeaux
    WHERE lot_id = v_lot_id
  )
  WHERE id = v_lot_id;
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.fn_sync_nb_cadeaux() OWNER TO postgres;

--
-- Name: nettoyer_donnees_expires(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.nettoyer_donnees_expires() RETURNS TABLE(otp_supprimes bigint, sessions_supprimees bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_otp      BIGINT;
  v_sessions BIGINT;
BEGIN
  DELETE FROM otp_codes WHERE expires_at < now();
  GET DIAGNOSTICS v_otp = ROW_COUNT;

  DELETE FROM sessions
  WHERE expires_at < now() OR is_revoked = true;
  GET DIAGNOSTICS v_sessions = ROW_COUNT;

  RETURN QUERY SELECT v_otp, v_sessions;
END;
$$;


ALTER FUNCTION public.nettoyer_donnees_expires() OWNER TO postgres;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    pack_id uuid,
    montant integer NOT NULL,
    methode public.payment_method NOT NULL,
    statut public.transaction_status DEFAULT 'pending'::public.transaction_status NOT NULL,
    reference text,
    reference_operateur text,
    telephone_paiement text,
    tentatives_ajout integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    note_admin text,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transactions_montant_check CHECK ((montant > 0)),
    CONSTRAINT transactions_tentatives_ajout_check CHECK ((tentatives_ajout >= 0))
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Name: valider_achat_pack(uuid, uuid, public.payment_method, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.valider_achat_pack(p_user_id uuid, p_pack_id uuid, p_methode public.payment_method, p_reference text, p_telephone_paiement text DEFAULT NULL::text) RETURNS public.transactions
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_pack        packs%ROWTYPE;
  v_transaction transactions%ROWTYPE;
  v_solde_avant INTEGER;
  v_solde_apres INTEGER;
BEGIN
  -- Vérifier le pack
  SELECT * INTO v_pack
  FROM packs WHERE id = p_pack_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pack introuvable ou inactif' USING ERRCODE = 'P0002';
  END IF;

  -- Référence unique
  IF EXISTS (SELECT 1 FROM transactions WHERE reference = p_reference) THEN
    RAISE EXCEPTION 'Référence déjà utilisée' USING ERRCODE = 'P0001';
  END IF;

  -- Récupérer le solde actuel
  SELECT solde INTO v_solde_avant
  FROM users WHERE id = p_user_id FOR UPDATE;

  v_solde_apres := v_solde_avant + v_pack.prix;

  -- Créer la transaction
  INSERT INTO transactions
    (user_id, pack_id, montant, methode, statut, reference,
     tentatives_ajout, telephone_paiement)
  VALUES
    (p_user_id, p_pack_id, v_pack.prix, p_methode, 'success',
     p_reference, v_pack.tentatives, p_telephone_paiement)
  RETURNING * INTO v_transaction;

  -- ✅ Créditer tentatives + solde + prix_par_tentative
  UPDATE users SET
    tentatives         = tentatives + v_pack.tentatives,
    solde              = solde + v_pack.prix,
    prix_par_tentative = v_pack.prix_par_tentative
  WHERE id = p_user_id;

  -- Mouvement de solde
  INSERT INTO mouvements_solde
    (user_id, type, montant, solde_avant, solde_apres,
     description, transaction_id)
  VALUES
    (p_user_id, 'depot', v_pack.prix, v_solde_avant, v_solde_apres,
     'Achat pack ' || v_pack.nom, v_transaction.id);

  -- Notification
  INSERT INTO notifications (user_id, type, titre, message, metadata)
  VALUES (
    p_user_id, 'paiement',
    '✅ Pack acheté avec succès',
    v_pack.tentatives || ' tentatives + ' ||
    v_pack.prix || ' FCFA ajoutés à votre compte.',
    jsonb_build_object(
      'transaction_id', v_transaction.id,
      'pack_id',        p_pack_id,
      'tentatives',     v_pack.tentatives,
      'solde_credite',  v_pack.prix
    )
  );

  -- Audit
  INSERT INTO audit_logs (user_id, action, details)
  VALUES (
    p_user_id, 'achat_pack',
    jsonb_build_object(
      'transaction_id',    v_transaction.id,
      'pack_id',           p_pack_id,
      'montant',           v_pack.prix,
      'methode',           p_methode::text,
      'tentatives',        v_pack.tentatives,
      'prix_par_tentative', v_pack.prix_par_tentative
    )
  );

  RETURN v_transaction;
END;
$$;


ALTER FUNCTION public.valider_achat_pack(p_user_id uuid, p_pack_id uuid, p_methode public.payment_method, p_reference text, p_telephone_paiement text) OWNER TO postgres;

--
-- Name: verifier_otp(uuid, text, public.otp_type); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verifier_otp(p_user_id uuid, p_code text, p_type public.otp_type) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_otp otp_codes%ROWTYPE;
BEGIN
  -- Récupérer le dernier OTP valide avec verrouillage
  SELECT * INTO v_otp
  FROM otp_codes
  WHERE user_id  = p_user_id
    AND type     = p_type
    AND is_used  = false
    AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Trop de tentatives → invalider l'OTP
  IF v_otp.attempts >= v_otp.max_attempts THEN
    UPDATE otp_codes SET is_used = true WHERE id = v_otp.id;
    RAISE EXCEPTION 'Trop de tentatives, OTP invalidé'
      USING ERRCODE = 'P0005';
  END IF;

  -- Mauvais code → incrémenter les tentatives
  IF v_otp.code <> p_code THEN
    UPDATE otp_codes SET attempts = attempts + 1 WHERE id = v_otp.id;
    RETURN false;
  END IF;

  -- ✅ Code correct → marquer comme utilisé
  UPDATE otp_codes SET is_used = true WHERE id = v_otp.id;

  -- Marquer le téléphone/email comme vérifié
  UPDATE users SET
    is_verified           = true,
    telephone_verified_at = CASE WHEN p_type = 'sms'
                              THEN now()
                              ELSE telephone_verified_at END,
    email_verified_at     = CASE WHEN p_type = 'email'
                              THEN now()
                              ELSE email_verified_at END
  WHERE id = p_user_id;

  INSERT INTO audit_logs (user_id, action)
  VALUES (p_user_id, 'verification_otp');

  RETURN true;
END;
$$;


ALTER FUNCTION public.verifier_otp(p_user_id uuid, p_code text, p_type public.otp_type) OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id uuid,
    admin_id uuid,
    action public.audit_action NOT NULL,
    details jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: cadeaux; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cadeaux (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    lot_id uuid NOT NULL,
    nom text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    icon text DEFAULT '🎁'::text NOT NULL,
    prix_reel integer DEFAULT 0 NOT NULL,
    categorie public.gift_category DEFAULT 'aucun'::public.gift_category NOT NULL,
    is_winner boolean DEFAULT false NOT NULL,
    is_loser boolean DEFAULT true NOT NULL,
    quantite integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cadeaux_nom_check CHECK ((TRIM(BOTH FROM nom) <> ''::text)),
    CONSTRAINT cadeaux_prix_reel_check CHECK ((prix_reel >= 0)),
    CONSTRAINT cadeaux_quantite_check CHECK ((quantite > 0)),
    CONSTRAINT winner_has_value CHECK (((NOT is_winner) OR (prix_reel > 0))),
    CONSTRAINT winner_xor_loser CHECK ((NOT (is_winner AND is_loser)))
);


ALTER TABLE public.cadeaux OWNER TO postgres;

--
-- Name: config_systeme; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.config_systeme (
    cle text NOT NULL,
    valeur text NOT NULL,
    description text,
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT config_systeme_cle_check CHECK ((TRIM(BOTH FROM cle) <> ''::text))
);


ALTER TABLE public.config_systeme OWNER TO postgres;

--
-- Name: livraisons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.livraisons (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tirage_id uuid NOT NULL,
    user_id uuid NOT NULL,
    statut public.livraison_status DEFAULT 'en_attente'::public.livraison_status NOT NULL,
    adresse_livraison text,
    contact_livraison text,
    responsable_id uuid,
    date_contact timestamp with time zone,
    date_livraison timestamp with time zone,
    notes text,
    photos_urls text[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.livraisons OWNER TO postgres;

--
-- Name: lots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lots (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nom text NOT NULL,
    subtitle text DEFAULT ''::text NOT NULL,
    icon text DEFAULT '🎁'::text NOT NULL,
    prix_min integer NOT NULL,
    prix_max integer NOT NULL,
    nb_cadeaux integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    ordre integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lots_nb_cadeaux_check CHECK ((nb_cadeaux >= 0)),
    CONSTRAINT lots_nom_check CHECK ((TRIM(BOTH FROM nom) <> ''::text)),
    CONSTRAINT lots_prix_max_check CHECK ((prix_max > 0)),
    CONSTRAINT lots_prix_min_check CHECK ((prix_min > 0)),
    CONSTRAINT prix_lot_coherent CHECK ((prix_max >= prix_min))
);


ALTER TABLE public.lots OWNER TO postgres;

--
-- Name: mouvements_solde; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mouvements_solde (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type public.mouvement_type NOT NULL,
    montant integer NOT NULL,
    solde_avant integer NOT NULL,
    solde_apres integer NOT NULL,
    description text,
    transaction_id uuid,
    admin_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mouvements_solde_montant_check CHECK ((montant <> 0)),
    CONSTRAINT mouvements_solde_solde_apres_check CHECK ((solde_apres >= 0)),
    CONSTRAINT mouvements_solde_solde_avant_check CHECK ((solde_avant >= 0)),
    CONSTRAINT solde_coherent CHECK ((solde_apres = (solde_avant + montant)))
);


ALTER TABLE public.mouvements_solde OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type public.notif_type DEFAULT 'systeme'::public.notif_type NOT NULL,
    titre text NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    read_at timestamp with time zone,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notifications_message_check CHECK ((TRIM(BOTH FROM message) <> ''::text)),
    CONSTRAINT notifications_titre_check CHECK ((TRIM(BOTH FROM titre) <> ''::text))
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: otp_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp_codes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    telephone text,
    email text,
    code text NOT NULL,
    type public.otp_type DEFAULT 'sms'::public.otp_type NOT NULL,
    is_used boolean DEFAULT false NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 3 NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:05:00'::interval) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT otp_codes_attempts_check CHECK ((attempts >= 0)),
    CONSTRAINT otp_codes_code_check CHECK ((code ~ '^\d{6}$'::text)),
    CONSTRAINT otp_codes_max_attempts_check CHECK ((max_attempts > 0)),
    CONSTRAINT otp_recipient CHECK (((telephone IS NOT NULL) OR (email IS NOT NULL)))
);


ALTER TABLE public.otp_codes OWNER TO postgres;

--
-- Name: packs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.packs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nom text DEFAULT ''::text NOT NULL,
    tentatives integer NOT NULL,
    prix integer NOT NULL,
    prix_par_tentative integer NOT NULL,
    badge text,
    is_popular boolean DEFAULT false NOT NULL,
    is_best_value boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT packs_prix_check CHECK ((prix > 0)),
    CONSTRAINT packs_prix_par_tentative_check CHECK ((prix_par_tentative > 0)),
    CONSTRAINT packs_tentatives_check CHECK ((tentatives > 0))
);


ALTER TABLE public.packs OWNER TO postgres;

--
-- Name: parrainages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parrainages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    parrain_id uuid NOT NULL,
    filleul_id uuid NOT NULL,
    bonus_verse boolean DEFAULT false NOT NULL,
    montant_bonus integer DEFAULT 0 NOT NULL,
    verse_le timestamp with time zone,
    transaction_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT no_self_parrainage CHECK ((parrain_id <> filleul_id)),
    CONSTRAINT parrainages_montant_bonus_check CHECK ((montant_bonus >= 0))
);


ALTER TABLE public.parrainages OWNER TO postgres;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    refresh_token text,
    expires_at timestamp with time zone DEFAULT (now() + '24:00:00'::interval) NOT NULL,
    refresh_expires_at timestamp with time zone DEFAULT (now() + '30 days'::interval),
    last_used_at timestamp with time zone DEFAULT now() NOT NULL,
    ip_address inet,
    user_agent text,
    is_revoked boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nom text NOT NULL,
    prenom text NOT NULL,
    telephone text NOT NULL,
    email text,
    mot_de_passe_hash text NOT NULL,
    role public.user_role DEFAULT 'joueur'::public.user_role NOT NULL,
    ville text,
    quartier text,
    commune text,
    province text,
    region text,
    pays text DEFAULT 'Burkina Faso'::text NOT NULL,
    adresse_complete text,
    solde integer DEFAULT 0 NOT NULL,
    tentatives integer DEFAULT 0 NOT NULL,
    gagnes integer DEFAULT 0 NOT NULL,
    parrainages integer DEFAULT 0 NOT NULL,
    code_parrain text DEFAULT upper("substring"((gen_random_uuid())::text, 1, 8)) NOT NULL,
    parrain_id uuid,
    failed_login_attempts integer DEFAULT 0 NOT NULL,
    locked_until timestamp with time zone,
    last_login_at timestamp with time zone,
    last_login_ip inet,
    is_verified boolean DEFAULT false NOT NULL,
    telephone_verified_at timestamp with time zone,
    email_verified_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    deleted_at timestamp with time zone,
    avatar_url text,
    note_admin text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    prix_par_tentative integer DEFAULT 0 NOT NULL,
    credit_converti integer DEFAULT 0 NOT NULL,
    CONSTRAINT no_self_referral CHECK ((parrain_id <> id)),
    CONSTRAINT users_email_check CHECK ((email ~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$'::text)),
    CONSTRAINT users_failed_login_attempts_check CHECK ((failed_login_attempts >= 0)),
    CONSTRAINT users_gagnes_check CHECK ((gagnes >= 0)),
    CONSTRAINT users_nom_check CHECK ((TRIM(BOTH FROM nom) <> ''::text)),
    CONSTRAINT users_parrainages_check CHECK ((parrainages >= 0)),
    CONSTRAINT users_prenom_check CHECK ((TRIM(BOTH FROM prenom) <> ''::text)),
    CONSTRAINT users_solde_check CHECK ((solde >= 0)),
    CONSTRAINT users_telephone_check CHECK ((telephone ~ '^\+?[0-9]{8,15}$'::text)),
    CONSTRAINT users_tentatives_check CHECK ((tentatives >= 0))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: v_gains_a_livrer; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_gains_a_livrer AS
 SELECT t.id AS tirage_id,
    t.created_at AS date_tirage,
    t.valeur_gagnee,
    t.statut_livraison,
    u.nom,
    u.prenom,
    u.telephone,
    u.ville,
    u.quartier,
    l.nom AS lot,
    c.nom AS cadeau,
    c.prix_reel,
    c.categorie,
    lv.id AS livraison_id,
    lv.statut AS livraison_statut,
    lv.adresse_livraison,
    lv.contact_livraison,
    lv.notes,
    lv.date_livraison
   FROM ((((public.tirages t
     JOIN public.users u ON ((u.id = t.user_id)))
     JOIN public.lots l ON ((l.id = t.lot_id)))
     JOIN public.cadeaux c ON ((c.id = t.cadeau_id)))
     LEFT JOIN public.livraisons lv ON ((lv.tirage_id = t.id)))
  WHERE ((t.is_winner = true) AND (t.statut_livraison <> 'livre'::public.livraison_status))
  ORDER BY t.created_at;


ALTER VIEW public.v_gains_a_livrer OWNER TO postgres;

--
-- Name: v_leaderboard; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_leaderboard AS
 SELECT u.id,
    u.nom,
    u.prenom,
    u.ville,
    count(t.id) AS nb_tirages,
    count(t.id) FILTER (WHERE t.is_winner) AS nb_gains,
    COALESCE(sum(t.valeur_gagnee), (0)::bigint) AS valeur_totale,
    max(t.created_at) AS dernier_tirage
   FROM (public.users u
     LEFT JOIN public.tirages t ON ((t.user_id = u.id)))
  WHERE ((u.deleted_at IS NULL) AND (u.is_active = true))
  GROUP BY u.id, u.nom, u.prenom, u.ville
  ORDER BY (count(t.id) FILTER (WHERE t.is_winner)) DESC, COALESCE(sum(t.valeur_gagnee), (0)::bigint) DESC;


ALTER VIEW public.v_leaderboard OWNER TO postgres;

--
-- Name: v_stats_dashboard; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_stats_dashboard AS
 SELECT ( SELECT count(*) AS count
           FROM public.users
          WHERE (users.deleted_at IS NULL)) AS total_joueurs,
    ( SELECT count(*) AS count
           FROM public.users
          WHERE ((users.created_at > (now() - '30 days'::interval)) AND (users.deleted_at IS NULL))) AS nouveaux_30j,
    ( SELECT count(*) AS count
           FROM public.users
          WHERE ((users.is_active = false) AND (users.deleted_at IS NULL))) AS joueurs_suspendus,
    ( SELECT count(*) AS count
           FROM public.tirages) AS total_tirages,
    ( SELECT count(*) AS count
           FROM public.tirages
          WHERE (tirages.is_winner = true)) AS total_gains,
    ( SELECT count(*) AS count
           FROM public.tirages
          WHERE (tirages.created_at > (now() - '30 days'::interval))) AS tirages_30j,
    ( SELECT COALESCE(sum(transactions.montant), (0)::bigint) AS "coalesce"
           FROM public.transactions
          WHERE (transactions.statut = 'success'::public.transaction_status)) AS revenus_total,
    ( SELECT COALESCE(sum(transactions.montant), (0)::bigint) AS "coalesce"
           FROM public.transactions
          WHERE ((transactions.statut = 'success'::public.transaction_status) AND (transactions.created_at > (now() - '30 days'::interval)))) AS revenus_30j,
    ( SELECT count(*) AS count
           FROM public.livraisons
          WHERE (livraisons.statut = 'en_attente'::public.livraison_status)) AS livraisons_en_attente,
    ( SELECT count(*) AS count
           FROM public.livraisons
          WHERE (livraisons.statut = 'livre'::public.livraison_status)) AS livraisons_terminees;


ALTER VIEW public.v_stats_dashboard OWNER TO postgres;

--
-- Name: v_transactions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_transactions AS
 SELECT tx.id,
    tx.montant,
    tx.methode,
    tx.statut,
    tx.reference,
    tx.tentatives_ajout,
    tx.telephone_paiement,
    tx.created_at,
    u.nom AS user_nom,
    u.prenom AS user_prenom,
    u.telephone AS user_telephone,
    p.nom AS pack_nom,
    p.tentatives AS pack_tentatives,
    p.badge AS pack_badge
   FROM ((public.transactions tx
     JOIN public.users u ON ((u.id = tx.user_id)))
     LEFT JOIN public.packs p ON ((p.id = tx.pack_id)));


ALTER VIEW public.v_transactions OWNER TO postgres;

--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: cadeaux cadeaux_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cadeaux
    ADD CONSTRAINT cadeaux_pkey PRIMARY KEY (id);


--
-- Name: config_systeme config_systeme_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_systeme
    ADD CONSTRAINT config_systeme_pkey PRIMARY KEY (cle);


--
-- Name: livraisons livraisons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livraisons
    ADD CONSTRAINT livraisons_pkey PRIMARY KEY (id);


--
-- Name: livraisons livraisons_tirage_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livraisons
    ADD CONSTRAINT livraisons_tirage_id_key UNIQUE (tirage_id);


--
-- Name: lots lots_nom_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT lots_nom_key UNIQUE (nom);


--
-- Name: lots lots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT lots_pkey PRIMARY KEY (id);


--
-- Name: mouvements_solde mouvements_solde_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_solde
    ADD CONSTRAINT mouvements_solde_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: otp_codes otp_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_pkey PRIMARY KEY (id);


--
-- Name: packs packs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.packs
    ADD CONSTRAINT packs_pkey PRIMARY KEY (id);


--
-- Name: parrainages parrainages_parrain_id_filleul_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parrainages
    ADD CONSTRAINT parrainages_parrain_id_filleul_id_key UNIQUE (parrain_id, filleul_id);


--
-- Name: parrainages parrainages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parrainages
    ADD CONSTRAINT parrainages_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_refresh_token_key UNIQUE (refresh_token);


--
-- Name: sessions sessions_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_token_key UNIQUE (token);


--
-- Name: tirages tirages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tirages
    ADD CONSTRAINT tirages_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_reference_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_reference_key UNIQUE (reference);


--
-- Name: users users_code_parrain_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_code_parrain_key UNIQUE (code_parrain);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_telephone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_telephone_key UNIQUE (telephone);


--
-- Name: idx_audit_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_action ON public.audit_logs USING btree (action, created_at DESC);


--
-- Name: idx_audit_admin_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_admin_id ON public.audit_logs USING btree (admin_id) WHERE (admin_id IS NOT NULL);


--
-- Name: idx_audit_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_created_at ON public.audit_logs USING btree (created_at DESC);


--
-- Name: idx_audit_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_user_id ON public.audit_logs USING btree (user_id, created_at DESC);


--
-- Name: idx_cadeaux_lot_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cadeaux_lot_id ON public.cadeaux USING btree (lot_id);


--
-- Name: idx_cadeaux_winner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cadeaux_winner ON public.cadeaux USING btree (lot_id, is_winner);


--
-- Name: idx_livraisons_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_livraisons_statut ON public.livraisons USING btree (statut);


--
-- Name: idx_livraisons_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_livraisons_user_id ON public.livraisons USING btree (user_id);


--
-- Name: idx_lots_actif; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lots_actif ON public.lots USING btree (is_active, ordre);


--
-- Name: idx_mouvements_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mouvements_created_at ON public.mouvements_solde USING btree (created_at DESC);


--
-- Name: idx_mouvements_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mouvements_type ON public.mouvements_solde USING btree (type);


--
-- Name: idx_mouvements_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mouvements_user_id ON public.mouvements_solde USING btree (user_id);


--
-- Name: idx_notifs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifs_created_at ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_notifs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifs_user_id ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: idx_notifs_user_unread; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifs_user_unread ON public.notifications USING btree (user_id, is_read) WHERE (is_read = false);


--
-- Name: idx_otp_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_otp_lookup ON public.otp_codes USING btree (user_id, type, is_used, expires_at) WHERE (is_used = false);


--
-- Name: idx_packs_actif; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_packs_actif ON public.packs USING btree (is_active, prix);


--
-- Name: idx_parrainages_filleul; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parrainages_filleul ON public.parrainages USING btree (filleul_id);


--
-- Name: idx_parrainages_parrain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parrainages_parrain ON public.parrainages USING btree (parrain_id);


--
-- Name: idx_sessions_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_expires_at ON public.sessions USING btree (expires_at) WHERE (is_revoked = false);


--
-- Name: idx_sessions_refresh; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_refresh ON public.sessions USING btree (refresh_token) WHERE (is_revoked = false);


--
-- Name: idx_sessions_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_token ON public.sessions USING btree (token) WHERE (is_revoked = false);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_tirages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tirages_created_at ON public.tirages USING btree (created_at DESC);


--
-- Name: idx_tirages_livraison; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tirages_livraison ON public.tirages USING btree (statut_livraison) WHERE (is_winner = true);


--
-- Name: idx_tirages_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tirages_user_id ON public.tirages USING btree (user_id);


--
-- Name: idx_tirages_user_winner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tirages_user_winner ON public.tirages USING btree (user_id, is_winner, created_at DESC);


--
-- Name: idx_tirages_winner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tirages_winner ON public.tirages USING btree (is_winner) WHERE (is_winner = true);


--
-- Name: idx_tx_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tx_created_at ON public.transactions USING btree (created_at DESC);


--
-- Name: idx_tx_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tx_statut ON public.transactions USING btree (statut);


--
-- Name: idx_tx_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tx_user_id ON public.transactions USING btree (user_id);


--
-- Name: idx_tx_user_statut; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tx_user_statut ON public.transactions USING btree (user_id, statut, created_at DESC);


--
-- Name: idx_users_actif; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_actif ON public.users USING btree (is_active, deleted_at);


--
-- Name: idx_users_code_parrain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_code_parrain ON public.users USING btree (code_parrain);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: idx_users_parrain_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_parrain_id ON public.users USING btree (parrain_id) WHERE (parrain_id IS NOT NULL);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role) WHERE (role = ANY (ARRAY['admin'::public.user_role, 'super_admin'::public.user_role]));


--
-- Name: idx_users_telephone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_telephone ON public.users USING btree (telephone);


--
-- Name: cadeaux trg_cadeaux_sync_nb; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cadeaux_sync_nb AFTER INSERT OR DELETE OR UPDATE OF quantite ON public.cadeaux FOR EACH ROW EXECUTE FUNCTION public.fn_sync_nb_cadeaux();


--
-- Name: cadeaux trg_cadeaux_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cadeaux_updated_at BEFORE UPDATE ON public.cadeaux FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: livraisons trg_livraisons_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_livraisons_updated_at BEFORE UPDATE ON public.livraisons FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: lots trg_lots_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_lots_updated_at BEFORE UPDATE ON public.lots FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: packs trg_packs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_packs_updated_at BEFORE UPDATE ON public.packs FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: transactions trg_transactions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_transactions_updated_at BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: audit_logs audit_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: cadeaux cadeaux_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cadeaux
    ADD CONSTRAINT cadeaux_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- Name: config_systeme config_systeme_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.config_systeme
    ADD CONSTRAINT config_systeme_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: livraisons livraisons_responsable_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livraisons
    ADD CONSTRAINT livraisons_responsable_id_fkey FOREIGN KEY (responsable_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: livraisons livraisons_tirage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livraisons
    ADD CONSTRAINT livraisons_tirage_id_fkey FOREIGN KEY (tirage_id) REFERENCES public.tirages(id) ON DELETE CASCADE;


--
-- Name: livraisons livraisons_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.livraisons
    ADD CONSTRAINT livraisons_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: mouvements_solde mouvements_solde_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_solde
    ADD CONSTRAINT mouvements_solde_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: mouvements_solde mouvements_solde_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_solde
    ADD CONSTRAINT mouvements_solde_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: mouvements_solde mouvements_solde_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mouvements_solde
    ADD CONSTRAINT mouvements_solde_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: otp_codes otp_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_codes
    ADD CONSTRAINT otp_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: parrainages parrainages_filleul_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parrainages
    ADD CONSTRAINT parrainages_filleul_id_fkey FOREIGN KEY (filleul_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: parrainages parrainages_parrain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parrainages
    ADD CONSTRAINT parrainages_parrain_id_fkey FOREIGN KEY (parrain_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: parrainages parrainages_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parrainages
    ADD CONSTRAINT parrainages_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: tirages tirages_cadeau_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tirages
    ADD CONSTRAINT tirages_cadeau_id_fkey FOREIGN KEY (cadeau_id) REFERENCES public.cadeaux(id) ON DELETE RESTRICT;


--
-- Name: tirages tirages_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tirages
    ADD CONSTRAINT tirages_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE RESTRICT;


--
-- Name: tirages tirages_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tirages
    ADD CONSTRAINT tirages_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE SET NULL;


--
-- Name: tirages tirages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tirages
    ADD CONSTRAINT tirages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: transactions transactions_pack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.packs(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: users users_parrain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_parrain_id_fkey FOREIGN KEY (parrain_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict RvbIN5NCBCdAQeJ5cGfcxjJUrCNQjiHGPDByNTHrokqs0L6mTsJUPMmbj6KUrEG

