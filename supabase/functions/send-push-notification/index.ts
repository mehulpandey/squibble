// Supabase Edge Function for sending APNs push notifications
// This function is triggered by database webhooks when:
// - A new doodle is sent (doodle_recipients INSERT)
// - A friend request is sent (friendships INSERT with status='pending')
// - A friend request is accepted (friendships UPDATE to status='accepted')

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "jose";

// APNs configuration
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!;
const BUNDLE_ID = "mehulpandey.squibble";

// Use sandbox APNs server for development builds from Xcode
// Note: Tokens from Xcode development builds only work with sandbox
const APNS_HOST = "api.sandbox.push.apple.com";

interface NotificationPayload {
  type: "new_doodle" | "friend_request" | "friend_accepted";
  recipient_id: string;
  sender_id?: string;
  sender_name?: string;
  doodle_id?: string;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE";
  table: string;
  record: Record<string, unknown>;
  old_record?: Record<string, unknown>;
}

// Generate JWT for APNs authentication using jose library
async function generateAPNsJWT(): Promise<string> {
  // Import the private key using jose
  const privateKey = await importPKCS8(APNS_PRIVATE_KEY, "ES256");

  // Create and sign the JWT
  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: APNS_KEY_ID })
    .setIssuer(APNS_TEAM_ID)
    .setIssuedAt()
    .sign(privateKey);

  return jwt;
}

// Send push notification via APNs
async function sendPushNotification(
  deviceToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  // Validate APNs config
  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY) {
    const missing = [];
    if (!APNS_KEY_ID) missing.push("APNS_KEY_ID");
    if (!APNS_TEAM_ID) missing.push("APNS_TEAM_ID");
    if (!APNS_PRIVATE_KEY) missing.push("APNS_PRIVATE_KEY");
    return { success: false, error: `Missing secrets: ${missing.join(", ")}` };
  }

  try {
    console.log(`APNS_KEY_ID: ${APNS_KEY_ID}, APNS_TEAM_ID: ${APNS_TEAM_ID}`);
    console.log(`APNS_PRIVATE_KEY length: ${APNS_PRIVATE_KEY?.length || 0}`);

    const jwt = await generateAPNsJWT();
    console.log(`Generated JWT length: ${jwt.length}`);

    const payload = {
      aps: {
        alert: {
          title,
          body,
        },
        sound: "default",
      },
      ...data,
    };

    console.log(`APNs Request Details:`);
    console.log(`  Host: ${APNS_HOST}`);
    console.log(`  Bundle ID (apns-topic): ${BUNDLE_ID}`);
    console.log(`  Token length: ${deviceToken.length}`);
    console.log(`  Token: ${deviceToken}`);

    // Ensure device token is clean (no whitespace, lowercase)
    const cleanToken = deviceToken.trim().toLowerCase();
    const cleanUrl = `https://${APNS_HOST}/3/device/${cleanToken}`;

    const response = await fetch(cleanUrl, {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "content-type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const responseText = await response.text();
    console.log(`APNs response: status=${response.status}, body=${responseText}, apns-id=${response.headers.get("apns-id")}`);

    if (!response.ok) {
      return { success: false, error: `APNs ${response.status}: ${responseText}` };
    }

    return { success: true };
  } catch (error) {
    return { success: false, error: `Exception: ${String(error)}` };
  }
}

Deno.serve(async (req) => {
  try {
    // Create Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json();

    // Handle direct API calls (for testing)
    if (body.type && body.recipient_id) {
      const payload = body as NotificationPayload;
      return await handleNotification(supabase, payload);
    }

    // Handle database webhook triggers
    const webhook = body as WebhookPayload;
    console.log(`Webhook received: ${webhook.type} on ${webhook.table}`);

    if (webhook.table === "doodle_recipients" && webhook.type === "INSERT") {
      // New doodle sent
      const record = webhook.record;
      const doodleId = record.doodle_id as string;
      const recipientId = record.recipient_id as string;

      // Get doodle details with sender info
      const { data: doodle } = await supabase
        .from("doodles")
        .select("sender_id, users!doodles_sender_id_fkey(display_name)")
        .eq("id", doodleId)
        .single();

      if (doodle) {
        const senderName = (doodle.users as { display_name: string })?.display_name || "Someone";
        return await handleNotification(supabase, {
          type: "new_doodle",
          recipient_id: recipientId,
          sender_id: doodle.sender_id,
          sender_name: senderName,
          doodle_id: doodleId,
        });
      }
    } else if (webhook.table === "friendships" && webhook.type === "INSERT") {
      // New friend request
      const record = webhook.record;
      if (record.status === "pending") {
        const requesterId = record.requester_id as string;
        const addresseeId = record.addressee_id as string;

        // Get requester's name
        const { data: requester } = await supabase
          .from("users")
          .select("display_name")
          .eq("id", requesterId)
          .single();

        if (requester) {
          return await handleNotification(supabase, {
            type: "friend_request",
            recipient_id: addresseeId,
            sender_id: requesterId,
            sender_name: requester.display_name,
          });
        }
      }
    } else if (webhook.table === "friendships" && webhook.type === "UPDATE") {
      // Friend request accepted
      const record = webhook.record;
      const oldRecord = webhook.old_record;

      if (oldRecord?.status === "pending" && record.status === "accepted") {
        const requesterId = record.requester_id as string;
        const addresseeId = record.addressee_id as string;

        // Get accepter's name (addressee accepted the request)
        const { data: accepter } = await supabase
          .from("users")
          .select("display_name")
          .eq("id", addresseeId)
          .single();

        if (accepter) {
          // Notify the original requester that their request was accepted
          return await handleNotification(supabase, {
            type: "friend_accepted",
            recipient_id: requesterId,
            sender_id: addresseeId,
            sender_name: accepter.display_name,
          });
        }
      }
    }

    return new Response(
      JSON.stringify({ success: true, message: "Webhook processed" }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error processing request:", error);
    return new Response(
      JSON.stringify({ success: false, error: String(error) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

async function handleNotification(
  supabase: ReturnType<typeof createClient>,
  payload: NotificationPayload
): Promise<Response> {
  // Get recipient's device token
  const { data: recipient } = await supabase
    .from("users")
    .select("device_token, display_name")
    .eq("id", payload.recipient_id)
    .single();

  if (!recipient?.device_token) {
    console.log(`No device token for user ${payload.recipient_id}`);
    return new Response(
      JSON.stringify({ success: false, message: "No device token" }),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  // Build notification content based on type
  let title: string;
  let body: string;
  const data: Record<string, string> = { type: payload.type };

  switch (payload.type) {
    case "new_doodle":
      title = "New Squibble!";
      body = `${payload.sender_name} sent you a doodle!`;
      if (payload.doodle_id) data.doodle_id = payload.doodle_id;
      if (payload.sender_id) data.sender_id = payload.sender_id;
      break;

    case "friend_request":
      title = "Friend Request";
      body = `${payload.sender_name} wants to connect with you`;
      if (payload.sender_id) data.sender_id = payload.sender_id;
      break;

    case "friend_accepted":
      title = "Request Accepted!";
      body = `${payload.sender_name} accepted your friend request`;
      if (payload.sender_id) data.sender_id = payload.sender_id;
      break;

    default:
      return new Response(
        JSON.stringify({ success: false, message: "Unknown notification type" }),
        { headers: { "Content-Type": "application/json" } }
      );
  }

  if (payload.sender_name) data.sender_name = payload.sender_name;

  // Send the notification
  const result = await sendPushNotification(recipient.device_token, title, body, data);

  return new Response(
    JSON.stringify({
      success: result.success,
      message: result.success ? "Notification sent" : "Failed to send",
      error: result.error
    }),
    { headers: { "Content-Type": "application/json" } }
  );
}
