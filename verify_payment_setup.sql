-- ========================================
-- VERIFICATION SCRIPT FOR PAYMENT SYSTEM
-- ========================================
-- Run this in Supabase SQL Editor to check if everything is set up correctly

-- 1. Check if payment_status column exists
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'service_requests' 
AND column_name = 'payment_status';

-- Expected: Should return 1 row showing payment_status column
-- If empty: You need to run add_payment_status_to_service_requests.sql

-- 2. Check if complete_request_payment function exists
SELECT 
    proname as function_name,
    prosecdef as is_security_definer,
    provolatile as volatility,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'complete_request_payment';

-- Expected: Should return 1 row with function details and prosecdef = true
-- If empty: You need to run complete_request_payment_function.sql

-- 3. Check recent service requests and their payment status
SELECT 
    id,
    status,
    payment_status,
    total_amount,
    created_at
FROM public.service_requests
ORDER BY created_at DESC
LIMIT 5;

-- Expected: Recent requests should have payment_status = 'held' if submitted
-- If payment_status is NULL or missing: Column wasn't added properly

-- 4. Test if function can be called (dry run check)
DO $$
BEGIN
    -- Just check if function exists and has correct parameters
    PERFORM 1 FROM pg_proc 
    WHERE proname = 'complete_request_payment' 
    AND pg_get_function_arguments(oid) = 'p_request_id uuid';
    
    IF FOUND THEN
        RAISE NOTICE '✅ Function complete_request_payment exists with correct parameters';
    ELSE
        RAISE NOTICE '❌ Function complete_request_payment not found or has wrong parameters';
    END IF;
END $$;

-- 5. Check wallet-related functions
SELECT proname as function_name
FROM pg_proc 
WHERE proname IN ('process_wallet_transaction', 'complete_request_payment')
ORDER BY proname;

-- Expected: Both functions should be listed
-- If missing: You need to run the respective SQL files
