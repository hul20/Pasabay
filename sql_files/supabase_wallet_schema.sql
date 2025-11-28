-- =====================================================
-- WALLET SYSTEM SCHEMA
-- =====================================================
-- This schema supports a pseudo payment system with wallets for travelers and requesters

-- =====================================================
-- 1. WALLETS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Balance
    balance DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick lookups
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);

-- =====================================================
-- 2. WALLET TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
    
    -- Transaction Details
    transaction_type TEXT NOT NULL CHECK (transaction_type IN (
        'top_up',
        'payment',
        'refund',
        'earning',
        'withdrawal'
    )),
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    
    -- Related Records (optional)
    related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    related_request_id UUID REFERENCES public.service_requests(id) ON DELETE SET NULL,
    related_trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,
    
    -- Description
    description TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON public.wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON public.wallet_transactions(transaction_type);

-- =====================================================
-- 3. FUNCTIONS & TRIGGERS
-- =====================================================

-- Function: Initialize wallet when user signs up
CREATE OR REPLACE FUNCTION initialize_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    -- Create wallet for new user
    INSERT INTO public.wallets (user_id, balance)
    VALUES (NEW.id, 0.00)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Create wallet on user creation
DROP TRIGGER IF EXISTS trigger_initialize_user_wallet ON auth.users;
CREATE TRIGGER trigger_initialize_user_wallet
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_wallet();

-- Function: Process wallet transaction (top-up, payment, etc.)
CREATE OR REPLACE FUNCTION process_wallet_transaction(
    p_user_id UUID,
    p_transaction_type TEXT,
    p_amount DECIMAL(10,2),
    p_description TEXT DEFAULT NULL,
    p_related_user_id UUID DEFAULT NULL,
    p_related_request_id UUID DEFAULT NULL,
    p_related_trip_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_wallet_id UUID;
    v_balance_before DECIMAL(10,2);
    v_balance_after DECIMAL(10,2);
    v_transaction_id UUID;
BEGIN
    -- Get wallet
    SELECT id, balance INTO v_wallet_id, v_balance_before
    FROM public.wallets
    WHERE user_id = p_user_id;
    
    IF v_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Wallet not found for user';
    END IF;
    
    -- Calculate new balance based on transaction type
    IF p_transaction_type IN ('top_up', 'refund', 'earning') THEN
        v_balance_after := v_balance_before + p_amount;
    ELSIF p_transaction_type IN ('payment', 'withdrawal') THEN
        v_balance_after := v_balance_before - p_amount;
        
        -- Check sufficient balance
        IF v_balance_after < 0 THEN
            RAISE EXCEPTION 'Insufficient balance';
        END IF;
    ELSE
        RAISE EXCEPTION 'Invalid transaction type';
    END IF;
    
    -- Update wallet balance
    UPDATE public.wallets
    SET balance = v_balance_after, updated_at = NOW()
    WHERE id = v_wallet_id;
    
    -- Record transaction
    INSERT INTO public.wallet_transactions (
        wallet_id,
        transaction_type,
        amount,
        balance_before,
        balance_after,
        description,
        related_user_id,
        related_request_id,
        related_trip_id
    ) VALUES (
        v_wallet_id,
        p_transaction_type,
        p_amount,
        v_balance_before,
        v_balance_after,
        p_description,
        p_related_user_id,
        p_related_request_id,
        p_related_trip_id
    )
    RETURNING id INTO v_transaction_id;
    
    -- Return result
    RETURN json_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'balance_before', v_balance_before,
        'balance_after', v_balance_after
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Wallet Policies
-- Users can view their own wallet
CREATE POLICY "Users can view their own wallet"
    ON public.wallets FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own wallet (for top-ups via function)
CREATE POLICY "Users can update their own wallet"
    ON public.wallets FOR UPDATE
    USING (auth.uid() = user_id);

-- Wallet Transactions Policies
-- Users can view their own transactions
CREATE POLICY "Users can view their own transactions"
    ON public.wallet_transactions FOR SELECT
    USING (
        wallet_id IN (
            SELECT id FROM public.wallets WHERE user_id = auth.uid()
        )
    );

-- Users can insert transactions (via function)
CREATE POLICY "Users can insert transactions"
    ON public.wallet_transactions FOR INSERT
    WITH CHECK (
        wallet_id IN (
            SELECT id FROM public.wallets WHERE user_id = auth.uid()
        )
    );

-- =====================================================
-- 5. INITIAL DATA SEEDING
-- =====================================================

-- Create wallets for existing users
INSERT INTO public.wallets (user_id, balance)
SELECT id, 0.00 FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

COMMENT ON TABLE public.wallets IS 'User wallets for pseudo payment system';
COMMENT ON TABLE public.wallet_transactions IS 'Transaction history for wallet operations';
