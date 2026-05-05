-- ============================================================
-- AgriFinance Financial Modeling Module (Supabase)
-- Setup script for MVP schema and policies
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Ensure updated_at trigger function exists
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FARM ITEMS (CROPS / LIVESTOCK)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.farm_items (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type           TEXT NOT NULL CHECK (item_type IN ('crop', 'livestock')),
  name                VARCHAR(100) NOT NULL,
  variety             VARCHAR(100),
  area_ha             NUMERIC(8,4),
  count               INT,
  planting_date       DATE,
  expected_harvest_date DATE,
  season              VARCHAR(50),
  status              TEXT NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'harvested', 'archived')),
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farm_items_user_status
  ON public.farm_items(user_id, status);

DROP TRIGGER IF EXISTS trg_farm_items_updated ON public.farm_items;
CREATE TRIGGER trg_farm_items_updated
  BEFORE UPDATE ON public.farm_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.farm_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Farm items are user-owned" ON public.farm_items;
CREATE POLICY "Farm items are user-owned"
  ON public.farm_items FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- FINANCIAL TRANSACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.financial_transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  farm_item_id      UUID REFERENCES public.farm_items(id) ON DELETE SET NULL,
  type              TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  amount            NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  currency          CHAR(3) NOT NULL DEFAULT 'PHP',
  transaction_date  DATE NOT NULL,
  category          VARCHAR(50) NOT NULL,
  description       VARCHAR(255),
  counterparty      VARCHAR(100),
  notes             TEXT,
  receipt_url       VARCHAR(512),
  entered_by        UUID,
  is_deleted        BOOLEAN NOT NULL DEFAULT FALSE,
  local_id          VARCHAR(100),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, local_id)
);

CREATE INDEX IF NOT EXISTS idx_fin_tx_user_date
  ON public.financial_transactions(user_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_fin_tx_user_type
  ON public.financial_transactions(user_id, type);
CREATE INDEX IF NOT EXISTS idx_fin_tx_farm_item
  ON public.financial_transactions(farm_item_id);

DROP TRIGGER IF EXISTS trg_fin_tx_updated ON public.financial_transactions;
CREATE TRIGGER trg_fin_tx_updated
  BEFORE UPDATE ON public.financial_transactions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.financial_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Financial transactions are user-owned" ON public.financial_transactions;
CREATE POLICY "Financial transactions are user-owned"
  ON public.financial_transactions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- TRANSACTION AUDIT LOG
-- ============================================================
CREATE TABLE IF NOT EXISTS public.transaction_audit (
  id              BIGSERIAL PRIMARY KEY,
  transaction_id  UUID NOT NULL REFERENCES public.financial_transactions(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action          TEXT NOT NULL CHECK (action IN ('create', 'update', 'delete')),
  old_data        JSONB,
  new_data        JSONB,
  performed_by    UUID,
  performed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tx_audit_transaction
  ON public.transaction_audit(transaction_id);

ALTER TABLE public.transaction_audit ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Transaction audit is user-owned" ON public.transaction_audit;
CREATE POLICY "Transaction audit is user-owned"
  ON public.transaction_audit FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- REPORTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.financial_reports (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  report_type      TEXT NOT NULL CHECK (report_type IN ('cashflow', 'profit_loss', 'credit_readiness', 'custom')),
  period_start     DATE,
  period_end       DATE,
  file_url         VARCHAR(512),
  share_token      VARCHAR(100) UNIQUE,
  share_expires_at TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fin_reports_user_type
  ON public.financial_reports(user_id, report_type);
CREATE INDEX IF NOT EXISTS idx_fin_reports_share_token
  ON public.financial_reports(share_token);

ALTER TABLE public.financial_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Financial reports are user-owned" ON public.financial_reports;
CREATE POLICY "Financial reports are user-owned"
  ON public.financial_reports FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- FORECASTING REFERENCE TABLES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.crop_cycles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_name         VARCHAR(100) NOT NULL,
  region            VARCHAR(20),
  planting_month    SMALLINT NOT NULL CHECK (planting_month BETWEEN 1 AND 12),
  harvest_month     SMALLINT NOT NULL CHECK (harvest_month BETWEEN 1 AND 12),
  input_heavy_months JSONB,
  avg_yield_kg      NUMERIC(10,2),
  avg_price_per_kg  NUMERIC(10,4),
  data_source       VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_crop_cycles_crop_region
  ON public.crop_cycles(crop_name, region);

ALTER TABLE public.crop_cycles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Crop cycles are readable" ON public.crop_cycles;
CREATE POLICY "Crop cycles are readable"
  ON public.crop_cycles FOR SELECT
  USING (true);

-- ============================================================
-- TRANSACTION CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.transaction_categories (
  category_key   VARCHAR(50) PRIMARY KEY,
  category_type  TEXT NOT NULL CHECK (category_type IN ('income', 'expense', 'both')),
  label_en       VARCHAR(100) NOT NULL,
  label_fil      VARCHAR(100),
  label_sw       VARCHAR(100),
  is_system      BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE public.transaction_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Transaction categories are readable" ON public.transaction_categories;
CREATE POLICY "Transaction categories are readable"
  ON public.transaction_categories FOR SELECT
  USING (true);

INSERT INTO public.transaction_categories (category_key, category_type, label_en, label_fil, label_sw, is_system)
VALUES
('crop_sale',      'income',  'Crop Sale',           'Benta ng Ani',        'Mauzo wa Mazao',      TRUE),
('livestock_sale', 'income',  'Livestock Sale',      'Benta ng Hayop',      'Mauzo wa Mifugo',     TRUE),
('subsidy',        'income',  'Subsidy / Grant',     'Subsidyo',            'Ruzuku',              TRUE),
('loan_received',  'income',  'Loan Received',       'Natanggap na Utang',  'Mkopo Uliopokelewa',  TRUE),
('other_income',   'income',  'Other Income',        'Iba pang Kita',       'Mapato Mengine',      TRUE),
('seeds',          'expense', 'Seeds',               'Binhi',               'Mbegu',               TRUE),
('fertilizer',     'expense', 'Fertilizer',          'Pataba',              'Mbolea',              TRUE),
('pesticide',      'expense', 'Pesticide/Herbicide', 'Pestisidyo',          'Dawa za Wadudu',      TRUE),
('labor',          'expense', 'Labor / Wages',       'Sahod ng Manggagawa', 'Mishahara',           TRUE),
('equipment',      'expense', 'Equipment / Rental',  'Kagamitan',           'Vifaa',               TRUE),
('transport',      'expense', 'Transport',           'Transportasyon',      'Usafiri',             TRUE),
('loan_repayment', 'expense', 'Loan Repayment',      'Bayad sa Utang',      'Kulipa Mkopo',        TRUE),
('other_expense',  'expense', 'Other Expense',       'Iba pang Gastos',     'Gharama Nyingine',    TRUE)
ON CONFLICT (category_key) DO NOTHING;

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

SELECT to_regclass('public.financial_transactions') AS transactions_table_created;
