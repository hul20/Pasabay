-- FIX: Update complete_request_payment to use service_fee instead of total_amount
-- The traveler should only earn the service_fee, not the full total_amount
-- For Pabakal: total_amount = product_cost + service_fee (but traveler only earns service_fee)
-- For Pasabay: total_amount = service_fee (same either way)

CREATE OR REPLACE FUNCTION complete_request_payment(p_request_id UUID)
RETURNS JSON 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_request RECORD;
    v_requester_name TEXT;
    v_traveler_name TEXT;
    v_conversation_id UUID;
    v_wallet_result JSON;
    v_earning_amount DECIMAL(10,2);
BEGIN
    -- Get request details
    SELECT * INTO v_request
    FROM public.service_requests
    WHERE id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Request not found';
    END IF;
    
    -- Use service_fee as the earning amount (NOT total_amount)
    -- This is the traveler's actual earning - excludes product cost for Pabakal
    v_earning_amount := v_request.service_fee;
    
    RAISE NOTICE 'Processing payment for request %', p_request_id;
    RAISE NOTICE 'Payment status: %', v_request.payment_status;
    RAISE NOTICE 'Service type: %', v_request.service_type;
    RAISE NOTICE 'Total amount (charged to requester): %', v_request.total_amount;
    RAISE NOTICE 'Service fee (traveler earning): %', v_earning_amount;
    RAISE NOTICE 'Traveler ID: %', v_request.traveler_id;
    
    -- Check if already completed
    IF v_request.payment_status = 'completed' THEN
        RETURN json_build_object('success', true, 'message', 'Payment already completed');
    END IF;
    
    -- Get requester and traveler names
    SELECT CONCAT(first_name, ' ', last_name) INTO v_requester_name
    FROM public.users
    WHERE id = v_request.requester_id;
    
    SELECT CONCAT(first_name, ' ', last_name) INTO v_traveler_name
    FROM public.users
    WHERE id = v_request.traveler_id;
    
    -- Get conversation ID
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE request_id = p_request_id;
    
    -- Send message to traveler that payment will be released
    IF v_conversation_id IS NOT NULL THEN
        INSERT INTO public.messages (
            conversation_id,
            sender_id,
            message_text,
            is_read,
            created_at
        ) VALUES (
            v_conversation_id,
            v_request.traveler_id,
            '💰 Payment is being released to you...',
            false,
            NOW()
        );
    END IF;
    
    -- Add earning to traveler wallet (using service_fee, not total_amount)
    RAISE NOTICE 'Calling process_wallet_transaction for traveler % with amount %', v_request.traveler_id, v_earning_amount;
    
    v_wallet_result := process_wallet_transaction(
        p_user_id := v_request.traveler_id,
        p_transaction_type := 'earning',
        p_amount := v_earning_amount,  -- FIXED: Use service_fee, not total_amount
        p_description := CONCAT('Service fee earned from ', COALESCE(v_requester_name, 'Requester'), ' (', v_request.service_type, ')'),
        p_related_user_id := v_request.requester_id,
        p_related_request_id := p_request_id,
        p_related_trip_id := v_request.trip_id
    );
    
    RAISE NOTICE 'Wallet transaction result: %', v_wallet_result;
    
    -- Check if wallet transaction was successful
    IF v_wallet_result->>'success' != 'true' THEN
        RAISE EXCEPTION 'Wallet transaction failed: %', v_wallet_result->>'error';
    END IF;
    
    -- Update payment status
    UPDATE public.service_requests
    SET payment_status = 'completed',
        updated_at = NOW()
    WHERE id = p_request_id;
    
    -- Send payment confirmation message in chat
    IF v_conversation_id IS NOT NULL THEN
        INSERT INTO public.messages (
            conversation_id,
            sender_id,
            message_text,
            is_read,
            created_at
        ) VALUES (
            v_conversation_id,
            v_request.traveler_id,
            CONCAT(
                '✅ Service Fee Received: ₱', v_earning_amount::TEXT, ' has been transferred to your wallet!'
            ),
            false,
            NOW()
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Payment completed successfully',
        'amount', v_earning_amount,
        'service_type', v_request.service_type
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION complete_request_payment IS 'Completes payment transfer from requester to traveler when request is marked as completed. Transfers service_fee (not total_amount) to traveler wallet.';

-- Grant permissions
GRANT EXECUTE ON FUNCTION complete_request_payment(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_request_payment(UUID) TO service_role;
