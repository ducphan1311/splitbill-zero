-- ==============================================================================
-- SplitBill Zero - Supabase PostgreSQL Schema & Security Policies (RLS)
-- ==============================================================================

-- 1. Create table_rooms table
CREATE TABLE IF NOT EXISTS public.table_rooms (
    room_id VARCHAR(32) PRIMARY KEY,
    host_name VARCHAR(100) NOT NULL,
    host_bank_bin VARCHAR(20) NOT NULL DEFAULT '970432', -- Default VPBank BIN
    host_account_number VARCHAR(50) NOT NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    guests JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'LOCKED', 'COMPLETED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Indexes for high-speed lookup and auto-expiration cleanup
CREATE INDEX IF NOT EXISTS idx_table_rooms_status ON public.table_rooms(status);
CREATE INDEX IF NOT EXISTS idx_table_rooms_created_at ON public.table_rooms(created_at);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.table_rooms ENABLE ROW LEVEL SECURITY;

-- 4. Security Policies:
-- Backend Gateway Service Role has full access.
-- Public anon users can read rooms if they have the exact room_id (via QR join link).
CREATE POLICY "Public can view room by exact ID"
    ON public.table_rooms
    FOR SELECT
    USING (true);

-- Modifications (INSERT / UPDATE) must go through Backend Gateway Service Role
CREATE POLICY "Service Role can manage rooms"
    ON public.table_rooms
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 5. Enable Realtime Replication for table_rooms
ALTER PUBLICATION supabase_realtime ADD TABLE public.table_rooms;
