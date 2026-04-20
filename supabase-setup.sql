-- ═══════════════════════════════════════════════════════
--  NAATU KOZHI - Supabase Database Setup
--  Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════════════════

-- 1. PRODUCTS TABLE (optional — products are currently in frontend)
CREATE TABLE IF NOT EXISTS products (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  category    TEXT NOT NULL,
  price       INTEGER NOT NULL,
  old_price   INTEGER,
  weight      TEXT,
  emoji       TEXT,
  badge       TEXT,
  badge_type  TEXT,
  description TEXT,
  rating      NUMERIC(3,1),
  reviews     INTEGER DEFAULT 0,
  in_stock    BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email    TEXT,
  payment_id    TEXT NOT NULL,
  items         JSONB NOT NULL,
  total_amount  INTEGER NOT NULL,
  delivery_charge INTEGER DEFAULT 0,
  status        TEXT DEFAULT 'confirmed' CHECK (status IN ('pending','confirmed','preparing','dispatched','delivered','cancelled')),
  address       JSONB,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. USER PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name   TEXT,
  phone       TEXT,
  address     TEXT,
  city        TEXT,
  pincode     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CART TABLE (server-side cart for persistence)
CREATE TABLE IF NOT EXISTS carts (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  items       JSONB DEFAULT '[]',
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- ═══════════════════════════════════════════════════════
--  ROW LEVEL SECURITY (RLS) POLICIES
-- ═══════════════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Products: anyone can read, only admins can write
CREATE POLICY "Products are publicly readable"
  ON products FOR SELECT USING (true);

-- Orders: users can only see their own orders
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Profiles: users can view and update their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can upsert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Carts: users can manage their own cart
CREATE POLICY "Users can manage own cart"
  ON carts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════
--  AUTO-CREATE PROFILE ON SIGNUP (Trigger)
-- ═══════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, phone)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'phone'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ═══════════════════════════════════════════════════════
--  SEED SAMPLE PRODUCTS
-- ═══════════════════════════════════════════════════════

INSERT INTO products (name, category, price, old_price, weight, emoji, badge, badge_type, description, rating, reviews) VALUES
('Whole Country Chicken',    'whole',      599,  749,  '~1 kg',     '🐓', 'Best Seller', 'hot', 'Full free-range country chicken, cleaned and dressed.', 4.9, 248),
('Curry Cut Naatu',          'curry-cut',  349,  NULL, '500g',      '🥘', 'Fresh Today', '',    'Perfectly portioned curry-cut pieces for authentic curry.', 4.8, 186),
('Boneless Breast Strips',   'boneless',   429,  499,  '500g',      '🍗', 'New',         'new', 'Tender boneless breast strips, ideal for grilling.', 4.7, 92),
('Drumstick Pack',           'special',    319,  NULL, '6 pieces',  '🍖', NULL,          '',    'Juicy country chicken drumsticks for BBQs.', 4.8, 143),
('Whole Chicken (Family)',   'whole',      1099, 1349, '~2 kg',     '🐔', 'Best Value',  'hot', 'Large whole naatu kozhi for big family meals.', 4.9, 312),
('Boneless Thigh Pieces',    'boneless',   479,  NULL, '500g',      '🥩', NULL,          '',    'Flavour-packed boneless thigh meat.', 4.8, 167),
('Country Chicken Keema',    'boneless',   399,  449,  '500g',      '🫕', 'New',         'new', 'Freshly minced naatu chicken for kebabs and curries.', 4.7, 58),
('Wings & Neck Combo',       'special',    249,  NULL, '500g',      '🍗', NULL,          '',    'Flavourful wings and neck pieces for rich stock.', 4.6, 74),
('Curry Cut (Small)',        'curry-cut',  229,  NULL, '250g',      '🥘', NULL,          '',    'Smaller pack of curry cut for singles or couples.', 4.7, 89),
('Jointed Half Bird',        'whole',      329,  399,  '~500g',     '🐓', NULL,          '',    'Half of a naatu kozhi, pre-jointed.', 4.8, 112),
('Curry Cut (Large)',        'curry-cut',  649,  749,  '1 kg',      '🥣', 'Popular',     'hot', 'Party-size curry cut pack.', 4.9, 203),
('Boneless Cubes',           'boneless',   459,  NULL, '500g',      '🧩', NULL,          '',    'Uniformly cut boneless cubes for tikka and biryani.', 4.7, 134);
