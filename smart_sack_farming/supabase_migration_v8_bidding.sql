-- Migration: Bidding system tables, enums, triggers, and helper procedures
-- Compatible with Postgres / Supabase

-- Requires pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;

-- ENUMs for strict values
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'crop_name_enum') THEN
        CREATE TYPE crop_name_enum AS ENUM ('okra','eggplant','ampalaya','squash','stringbeans');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'planting_status_enum') THEN
        CREATE TYPE planting_status_enum AS ENUM ('growing','harvesting','completed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'endorsement_status_enum') THEN
        CREATE TYPE endorsement_status_enum AS ENUM ('open','closed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bid_status_enum') THEN
        CREATE TYPE bid_status_enum AS ENUM ('pending','accepted','rejected');
    END IF;
END$$;

-- Planting records (farmers log planting activities)
CREATE TABLE IF NOT EXISTS public.planting_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  farmer_id uuid,
  crop_name crop_name_enum NOT NULL,
  area_planted_ha numeric(10,4) NOT NULL,
  estimated_yield_mt numeric(12,4) NOT NULL,
  planting_date date NOT NULL,
  expected_harvest_date date,
  status planting_status_enum NOT NULL DEFAULT 'growing',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  -- optional foreign key to auth.users (may be managed externally in Supabase)
  CONSTRAINT fk_farmer_user FOREIGN KEY (farmer_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_planting_expected_harvest ON public.planting_records(expected_harvest_date);

-- Market endorsements (MAO endorses planting records to market)
CREATE TABLE IF NOT EXISTS public.market_endorsements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  planting_record_id uuid NOT NULL REFERENCES public.planting_records(id) ON DELETE CASCADE,
  mao_id uuid,
  endorsement_date timestamptz NOT NULL DEFAULT now(),
  starting_bid_price numeric(12,2) NOT NULL,
  current_highest_bid numeric(12,2) NULL,
  status endorsement_status_enum NOT NULL DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_mao_user FOREIGN KEY (mao_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_endorsement_status ON public.market_endorsements(status);

-- Buyer bids
CREATE TABLE IF NOT EXISTS public.buyer_bids (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  endorsement_id uuid NOT NULL REFERENCES public.market_endorsements(id) ON DELETE CASCADE,
  buyer_id uuid,
  bid_amount numeric(12,2) NOT NULL,
  bid_date timestamptz NOT NULL DEFAULT now(),
  status bid_status_enum NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_buyer_user FOREIGN KEY (buyer_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_bids_endorsement ON public.buyer_bids(endorsement_id);

-- Trigger function: calculate expected_harvest_date based on crop maturity days
CREATE OR REPLACE FUNCTION public.trg_calc_expected_harvest_date()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  days integer;
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (NEW.crop_name IS DISTINCT FROM OLD.crop_name OR NEW.planting_date IS DISTINCT FROM OLD.planting_date)) THEN
    CASE NEW.crop_name
      WHEN 'okra' THEN days := 60;
      WHEN 'eggplant' THEN days := 75;
      WHEN 'ampalaya' THEN days := 65;
      WHEN 'squash' THEN days := 90;
      WHEN 'stringbeans' THEN days := 55;
      ELSE RAISE EXCEPTION 'Unknown crop value: %', NEW.crop_name;
    END CASE;
    NEW.expected_harvest_date := (NEW.planting_date + (days || ' days')::interval)::date;
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_planting_calc_expected_harvest
BEFORE INSERT OR UPDATE ON public.planting_records
FOR EACH ROW EXECUTE FUNCTION public.trg_calc_expected_harvest_date();

-- Trigger function: validate bids before insert
CREATE OR REPLACE FUNCTION public.trg_validate_bid_before_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  e_status endorsement_status_enum;
  current numeric;
BEGIN
  -- ensure endorsement is open
  SELECT status, starting_bid_price INTO e_status, current FROM public.market_endorsements WHERE id = NEW.endorsement_id;
  IF e_status IS NULL THEN
    RAISE EXCEPTION 'Endorsement not found: %', NEW.endorsement_id;
  END IF;
  IF e_status <> 'open' THEN
    RAISE EXCEPTION 'Cannot bid on endorsement with status: %', e_status;
  END IF;

  -- compute current highest (starting_bid_price or max existing bid where not rejected)
  SELECT GREATEST(current, COALESCE(MAX(b.bid_amount), 0)) INTO current
  FROM public.buyer_bids b
  WHERE b.endorsement_id = NEW.endorsement_id AND b.status <> 'rejected';

  IF NEW.bid_amount <= current THEN
    RAISE EXCEPTION 'Bid must be greater than current highest bid (%.2f)', current;
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_bid_validate BEFORE INSERT ON public.buyer_bids
FOR EACH ROW EXECUTE FUNCTION public.trg_validate_bid_before_insert();

-- Trigger function: update market_endorsements.current_highest_bid after bid changes
CREATE OR REPLACE FUNCTION public.trg_update_endorsement_highest()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  maxbid numeric;
  start numeric;
  eid uuid;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    eid := OLD.endorsement_id;
  ELSE
    eid := NEW.endorsement_id;
  END IF;

  SELECT starting_bid_price INTO start FROM public.market_endorsements WHERE id = eid;
  SELECT COALESCE(MAX(b.bid_amount), 0) INTO maxbid FROM public.buyer_bids b WHERE b.endorsement_id = eid AND b.status <> 'rejected';

  UPDATE public.market_endorsements
    SET current_highest_bid = GREATEST(start, maxbid), updated_at = now()
    WHERE id = eid;

  RETURN NULL;
END;
$$;

CREATE TRIGGER trg_bids_upsert AFTER INSERT OR UPDATE OR DELETE ON public.buyer_bids
FOR EACH ROW EXECUTE FUNCTION public.trg_update_endorsement_highest();

-- Stored procedure: accept a bid (marks bid accepted, other bids rejected, closes endorsement)
CREATE OR REPLACE FUNCTION public.accept_bid_and_close(accepted_bid_id uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  e_id uuid;
BEGIN
  -- ensure the bid exists and endorsement is open
  SELECT endorsement_id INTO e_id FROM public.buyer_bids WHERE id = accepted_bid_id;
  IF e_id IS NULL THEN
    RAISE EXCEPTION 'Bid not found: %', accepted_bid_id;
  END IF;

  UPDATE public.buyer_bids SET status = 'rejected' WHERE endorsement_id = e_id AND id <> accepted_bid_id;
  UPDATE public.buyer_bids SET status = 'accepted' WHERE id = accepted_bid_id;
  UPDATE public.market_endorsements SET status = 'closed', updated_at = now() WHERE id = e_id;

  PERFORM public.trg_update_endorsement_highest();
END;
$$;

-- Optional: policy placeholders for Supabase Row Level Security
-- (Enable and tailor these policies in Supabase dashboard as needed.)

COMMIT;
