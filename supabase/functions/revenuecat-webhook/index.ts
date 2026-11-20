// POST /functions/v1/revenuecat-webhook — notifications d'achats envoyées par RevenueCat :
// abonnements (US-11) et achats uniques (US-18, 19, 20, 21).
// Format : https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields
// Les droits de l'utilisateur sont mis à jour en base ; l'app ne fait que les lire.
import { admin, json, UUID_PATTERN } from "../_shared/http.ts";

// Même valeur que le champ « Authorization header » du webhook dans RevenueCat.
const EXPECTED_AUTHORIZATION = Deno.env.get("REVENUECAT_WEBHOOK_AUTHORIZATION") ?? "";

interface PurchaseEvent {
  id: string;
  type: string;
  event_timestamp_ms: number;
  app_user_id?: string | null;
  original_app_user_id?: string | null;
  aliases?: string[] | null;
  product_id?: string | null;
  period_type?: string | null;
  expiration_at_ms?: number | null;
  cancel_reason?: string | null;
  // Achats uniques (NON_RENEWING_PURCHASE) et leurs remboursements.
  transaction_id?: string | null;
  quantity?: number | null;
}

/** Comparaison en temps constant : ne révèle pas le secret caractère par caractère. */
function isSameSecret(received: string, expected: string): boolean {
  const a = new TextEncoder().encode(received);
  const b = new TextEncoder().encode(expected);
  if (a.length !== b.length) return false;
  let difference = 0;
  for (let index = 0; index < a.length; index++) difference |= a[index] ^ b[index];
  return difference === 0;
}

function parseEvent(body: unknown): PurchaseEvent | null {
  const event = (body as { event?: unknown } | null)?.event;
  if (typeof event !== "object" || event === null) return null;
  const { id, type, event_timestamp_ms } = event as Record<string, unknown>;
  const isValid = typeof id === "string" && id !== "" && typeof type === "string" &&
    typeof event_timestamp_ms === "number";
  return isValid ? (event as PurchaseEvent) : null;
}

/** L'app s'identifie auprès de RevenueCat avec l'identifiant Supabase de l'utilisateur. */
function userIdOf(event: PurchaseEvent): string | null {
  const candidates = [event.app_user_id, event.original_app_user_id, ...(event.aliases ?? [])];
  return candidates.find((candidate) => candidate != null && UUID_PATTERN.test(candidate)) ??
    null;
}

/** Date jusqu'à laquelle l'abonnement donne ses droits, d'après la notification. */
function expirationOf(event: PurchaseEvent): string | null {
  const isRefund = event.type === "CANCELLATION" && event.cancel_reason === "CUSTOMER_SUPPORT";
  // Remboursement ou expiration : l'accès s'arrête au plus tard à la date de la notification.
  if (isRefund || event.type === "EXPIRATION") {
    const end = Math.min(
      event.expiration_at_ms ?? event.event_timestamp_ms,
      event.event_timestamp_ms,
    );
    return new Date(end).toISOString();
  }
  return event.expiration_at_ms == null ? null : new Date(event.expiration_at_ms).toISOString();
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json(405, { error: "method_not_allowed" });

  const authorization = request.headers.get("Authorization") ?? "";
  if (EXPECTED_AUTHORIZATION === "" || !isSameSecret(authorization, EXPECTED_AUTHORIZATION)) {
    return json(401, { error: "unauthorized" });
  }

  const event = parseEvent(await request.json().catch(() => null));
  if (!event) return json(400, { error: "invalid_event" });

  const userId = userIdOf(event);
  // Identifiant inconnu (compte anonyme RevenueCat, test) : rien à faire, et répondre 200
  // évite que RevenueCat renvoie la notification en boucle.
  if (!userId) return json(200, { status: "ignored" });

  // La base aiguille selon le produit : abonnement ou achat unique.
  const { data: status, error } = await admin.rpc("apply_store_event", {
    p_event_id: event.id,
    p_user_id: userId,
    p_type: event.type,
    p_product_id: event.product_id ?? null,
    p_expires_at: expirationOf(event),
    p_in_trial: event.period_type === "TRIAL",
    p_event_at: new Date(event.event_timestamp_ms).toISOString(),
    p_transaction_id: event.transaction_id ?? null,
    p_quantity: event.quantity ?? 1,
    p_cancel_reason: event.cancel_reason ?? null,
  });
  if (error) {
    // Une réponse 5xx fait réessayer RevenueCat plus tard.
    console.error("Notification d'achat non appliquée", event.id, error.message);
    return json(500, { error: "internal" });
  }

  return json(200, { status });
});
