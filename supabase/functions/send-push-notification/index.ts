import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

// Get environment variables
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!

// Function to get OAuth2 access token
async function getAccessToken() {
  const toBase64Url = (str: string) => btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  
  const jwtHeader = toBase64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  
  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }
  
  const jwtClaimSetEncoded = toBase64Url(JSON.stringify(jwtClaimSet))
  const signatureInput = `${jwtHeader}.${jwtClaimSetEncoded}`
  
  // Import private key
  const privateKey = FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
  
  // Debug log (safe)
  console.log(`Using Client Email: ${FIREBASE_CLIENT_EMAIL}`);
  console.log(`Private Key Length: ${privateKey.length}`);
  
  const keyData = await crypto.subtle.importKey(
    'pkcs8',
    Uint8Array.from(atob(privateKey.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n|\r/g, '')), c => c.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )
  
  // Sign the JWT
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    keyData,
    new TextEncoder().encode(signatureInput)
  )
  
  const signatureBase64 = toBase64Url(String.fromCharCode(...new Uint8Array(signature)))
  const jwt = `${signatureInput}.${signatureBase64}`
  
  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  
  const tokenData = await tokenResponse.json()
  
  if (tokenData.error) {
    throw new Error(`Token Error: ${tokenData.error_description || tokenData.error}`);
  }
  
  return tokenData.access_token
}

serve(async (req) => {
  try {
    const { fcmToken, title, body, data } = await req.json()

    // Get OAuth2 access token
    const accessToken = await getAccessToken()

    // Send notification using FCM V1 API
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title,
              body,
            },
            data: data || {},
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channel_id: 'pasabay_notifications',
              },
            },
          },
        }),
      }
    )

    const result = await response.json()
    
    if (!response.ok) {
      console.error('FCM Error:', result)
      throw new Error(result.error?.message || 'Failed to send notification')
    }

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    console.error('Error sending push notification:', error)
    return new Response(JSON.stringify({ 
      success: false, 
      error: error.message || String(error)
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})