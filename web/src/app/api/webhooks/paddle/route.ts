import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const secret = process.env.PADDLE_WEBHOOK_SECRET;
  if (!secret) {
    return NextResponse.json({ error: "Paddle webhook not configured" }, { status: 503 });
  }

  try {
    const body = await req.json();
    const eventType = body.event_type;

    switch (eventType) {
      case "subscription.created":
        // TODO: Update user subscription in Supabase
        // Structured log for production observability
        console.info("[Paddle] subscription created:", body.data?.id);
        break;
      case "subscription.updated":
        // Structured log for production observability
        console.info("[Paddle] subscription updated:", body.data?.id);
        break;
      case "subscription.canceled":
        // Structured log for production observability
        console.info("[Paddle] subscription canceled:", body.data?.id);
        break;
      case "transaction.completed":
        // Structured log for production observability
        console.info("[Paddle] transaction completed:", body.data?.id);
        break;
      default:
        // Structured log for production observability
        console.info("[Paddle] webhook:", eventType);
    }

    return NextResponse.json({ received: true });
  } catch (err) {
    console.error("Paddle webhook error:", err);
    return NextResponse.json({ error: "Webhook processing failed" }, { status: 500 });
  }
}
