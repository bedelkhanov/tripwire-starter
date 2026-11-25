-- Структура базы для системы автопродаж (Cloudflare D1 / SQLite).
-- Время — unix-секунды. Создать: npx wrangler d1 execute <db> --remote --file=04-schema.sql

CREATE TABLE IF NOT EXISTS users (
  tg_id INTEGER PRIMARY KEY,          -- Telegram id покупателя
  username TEXT, first_name TEXT,
  source TEXT,                        -- параметр /start
  src TEXT, campaign TEXT, content TEXT, medium TEXT, term TEXT, ad_id TEXT, placement TEXT, -- метки рекламы
  created_at INTEGER NOT NULL, last_active INTEGER,
  nudges TEXT DEFAULT '',             -- какие сообщения цепочки уже ушли
  promo_until INTEGER,                -- до когда действует личная цена
  ref_by INTEGER,                     -- кто пригласил
  blocked INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS visitors (  -- заходы на сайт до бота
  id TEXT PRIMARY KEY, first_seen INTEGER NOT NULL, last_seen INTEGER, tg_id INTEGER,
  src TEXT, campaign TEXT, content TEXT, medium TEXT, term TEXT, ad_id TEXT, placement TEXT,
  fbclid TEXT, fbc TEXT, fbp TEXT, ip TEXT, ua TEXT, referrer TEXT
);

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY, title TEXT NOT NULL, subtitle TEXT,
  price INTEGER NOT NULL, upsell_price INTEGER, requires TEXT, sort INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS modules (   -- уроки внутри продукта
  product TEXT NOT NULL, idx INTEGER NOT NULL, title TEXT NOT NULL, body TEXT,
  video_provider TEXT DEFAULT 'r2', video_id TEXT, duration INTEGER, notes TEXT,
  PRIMARY KEY (product, idx)
);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY, tg_id INTEGER NOT NULL, product TEXT NOT NULL, amount INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', provider TEXT NOT NULL, provider_id TEXT, payment_url TEXT,
  is_sandbox INTEGER DEFAULT 0, created_at INTEGER NOT NULL, paid_at INTEGER, meta TEXT, delivered INTEGER
);
CREATE INDEX IF NOT EXISTS orders_tg ON orders(tg_id);
CREATE INDEX IF NOT EXISTS orders_status_paid ON orders(status, paid_at);

CREATE TABLE IF NOT EXISTS access (
  tg_id INTEGER NOT NULL, product TEXT NOT NULL, order_id TEXT, granted_at INTEGER NOT NULL,
  PRIMARY KEY (tg_id, product)
);

CREATE TABLE IF NOT EXISTS module_progress (
  tg_id INTEGER NOT NULL, product TEXT NOT NULL, idx INTEGER NOT NULL,
  position INTEGER DEFAULT 0, duration INTEGER DEFAULT 0, last_pos INTEGER,
  unlocked_at INTEGER, completed_at INTEGER,
  PRIMARY KEY (tg_id, product, idx)
);

CREATE TABLE IF NOT EXISTS funnel_events ( -- путь человека: visit, buy_click, bot_start, pay_open, purchase
  id INTEGER PRIMARY KEY AUTOINCREMENT, vid TEXT, tg_id INTEGER, event TEXT NOT NULL,
  order_id TEXT, at INTEGER NOT NULL, meta TEXT
);
CREATE INDEX IF NOT EXISTS funnel_events_vid ON funnel_events(vid);

CREATE TABLE IF NOT EXISTS ad_spend (  -- расход Meta по объявлениям, раз в час
  day TEXT NOT NULL, ad_id TEXT NOT NULL, ad_name TEXT, adset TEXT, campaign TEXT,
  spend REAL, currency TEXT, impressions INTEGER, clicks INTEGER, updated_at INTEGER,
  PRIMARY KEY (day, ad_id)
);

CREATE TABLE IF NOT EXISTS messages (  -- переписка в боте
  id INTEGER PRIMARY KEY AUTOINCREMENT, tg_id INTEGER NOT NULL, dir TEXT NOT NULL,
  text TEXT, media TEXT, via TEXT, owner_msg_id INTEGER, created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS msg_texts (k TEXT PRIMARY KEY, text TEXT, off INTEGER DEFAULT 0, updated_at INTEGER);

CREATE TABLE IF NOT EXISTS broadcasts (id TEXT PRIMARY KEY, text TEXT NOT NULL, button TEXT, segment TEXT NOT NULL,
  status TEXT NOT NULL, total INTEGER DEFAULT 0, created_at INTEGER NOT NULL, finished_at INTEGER);
CREATE TABLE IF NOT EXISTS broadcast_queue (bid TEXT NOT NULL, tg_id INTEGER NOT NULL, status TEXT NOT NULL,
  sent_at INTEGER, PRIMARY KEY (bid, tg_id));

CREATE TABLE IF NOT EXISTS ref_rewards (id TEXT PRIMARY KEY, referrer INTEGER NOT NULL, buyer INTEGER NOT NULL UNIQUE,
  order_id TEXT UNIQUE, amount INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending', created_at INTEGER NOT NULL, paid_at INTEGER);

CREATE TABLE IF NOT EXISTS settings (k TEXT PRIMARY KEY, v TEXT);
INSERT OR IGNORE INTO settings (k, v) VALUES
  ('promo_minutes', '15'), ('promo_price', '9900'), ('full_price', '20000'), ('ref_hours', '24'), ('usd_kzt', '445');
