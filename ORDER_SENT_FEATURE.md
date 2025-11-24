# Order Sent Feature Implementation

This feature allows travelers to mark an order as "Sent" and upload a proof of delivery (photo).

## Changes Made

1.  **Chat Interface (`lib/screens/chat_detail_page.dart`)**:
    *   Updated the "Request Details Bar" (top of chat) to include action buttons for the Traveler.
    *   Added "Details" button (left) and "Item Delivered" button (right).
    *   The "Item Delivered" button is enabled only when the request status is 'Accepted'.
    *   Clicking "Item Delivered" opens a modal to take a photo proof.
    *   Upon confirmation:
        *   The photo is uploaded to Supabase Storage (`proof-images`).
        *   The request status is updated to 'Order Sent'.
        *   The `proof_image_url` is saved to the request.
        *   An automated message is sent to the chat with the proof link.

2.  **Data Model (`lib/models/request.dart`)**:
    *   Added `proofImageUrl` field to `ServiceRequest`.
    *   Added `copyWith` method for state updates.

3.  **Database Schema (`add_order_sent_status.sql`)**:
    *   Added `proof_image_url` column to `service_requests` table.
    *   Updated `status` check constraint to include 'Order Sent'.
    *   Created `proof-images` storage bucket and policies.

## Required Actions

To make this feature work, you must run the SQL migration script in your Supabase Dashboard.

1.  Go to the **Supabase Dashboard**.
2.  Navigate to the **SQL Editor**.
3.  Click **New Query**.
4.  Copy and paste the contents of `add_order_sent_status.sql` (located in your project root).
5.  Click **Run**.

## Testing

1.  Log in as a Traveler.
2.  Go to a chat with an accepted request.
3.  You should see a check circle icon in the top bar.
4.  Tap it, take a photo, and confirm.
5.  The status should update, and a message should appear in the chat.
