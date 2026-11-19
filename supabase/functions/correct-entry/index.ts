// POST /functions/v1/correct-entry — corrige le journal du jour (US-05 à US-07).
// Le quota est réservé en base avant l'appel à Claude et rendu si la correction échoue.
import { createClient } from "npm:@supabase/supabase-js@2.119.2";
import {
  correctEntry,
  type Language,
  LANGUAGES,
  type UiLocale,
  UI_LOCALES,
  type Usage,
} from "./corrector.ts";

// Garde-fou large contre les requêtes abusives ; la limite de l'offre est appliquée en base.
const MAX_TEXT_LENGTH = 10_000;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

interface CorrectionRequest {
  text: string;
  language: Language;
  uiLocale: UiLocale;
  localDate: string;
  idempotencyKey: string;
}

function parseRequest(body: unknown): CorrectionRequest | null {
  if (typeof body !== "object" || body === null) return null;
  const { text, language, ui_locale, local_date, idempotency_key } = body as Record<
    string,
    unknown
  >;
  const isValid = typeof text === "string" && text.length <= MAX_TEXT_LENGTH &&
    LANGUAGES.includes(language as Language) &&
    UI_LOCALES.includes(ui_locale as UiLocale) &&
    typeof local_date === "string" && DATE_PATTERN.test(local_date) &&
    typeof idempotency_key === "string" && UUID_PATTERN.test(idempotency_key);
  if (!isValid) return null;
  return {
    text: text as string,
    language: language as Language,
    uiLocale: ui_locale as UiLocale,
    localDate: local_date as string,
    idempotencyKey: idempotency_key as string,
  };
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function userIdFrom(request: Request): Promise<string | null> {
  const token = request.headers.get("Authorization")?.replace(/^Bearer /i, "");
  if (!token) return null;
  const { data } = await admin.auth.getUser(token);
  return data.user?.id ?? null;
}

async function loadEntry(entryId: string): Promise<unknown> {
  const { data, error } = await admin
    .from("journal_entries")
    .select(
      "id, language, entry_date, original_text, corrected_text, " +
        "correction_items(position, original, corrected, category, explanation)",
    )
    .eq("id", entryId)
    .order("position", { referencedTable: "correction_items" })
    .single();
  if (error) throw error;
  return data;
}

async function recordUsage(userId: string, usage: Usage): Promise<void> {
  const { error } = await admin.from("ai_usage").insert({
    user_id: userId,
    feature: "correction_basic",
    model: usage.model,
    input_tokens: usage.inputTokens,
    output_tokens: usage.outputTokens,
  });
  if (error) console.error("Coût IA non journalisé", error.message);
}

/** Rend le quota du jour, puis répond avec l'erreur. */
async function releaseAndRespond(
  entryId: string,
  status: number,
  error: string,
): Promise<Response> {
  const { error: releaseError } = await admin.rpc("release_correction", { p_entry_id: entryId });
  if (releaseError) console.error("Réservation non annulée", releaseError.message);
  return json(status, { error });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json(405, { error: "method_not_allowed" });

  const userId = await userIdFrom(request);
  if (!userId) return json(401, { error: "unauthorized" });

  const input = parseRequest(await request.json().catch(() => null));
  if (!input) return json(400, { error: "invalid_input" });

  const { data: reservation, error: reservationError } = await admin.rpc("reserve_correction", {
    p_user_id: userId,
    p_language: input.language,
    p_entry_date: input.localDate,
    p_text: input.text,
    p_idempotency_key: input.idempotencyKey,
  });
  if (reservationError) {
    console.error("Réservation impossible", reservationError.message);
    return json(500, { error: "internal" });
  }

  if (reservation.status === "denied") {
    const { status: _status, reason, ...limits } = reservation;
    return json(403, { error: reason, ...limits });
  }
  const entryId: string = reservation.entry_id;
  if (reservation.status === "corrected") return json(200, await loadEntry(entryId));

  let result;
  try {
    result = await correctEntry(input.text, input.language, input.uiLocale);
  } catch (error) {
    // Jamais le texte du journal dans les journaux techniques.
    console.error("Correction IA en échec", error instanceof Error ? error.message : error);
    return releaseAndRespond(entryId, 503, "ai_unavailable");
  }

  if (result.outcome !== "corrected") {
    await recordUsage(userId, result.usage);
    return releaseAndRespond(
      entryId,
      422,
      result.outcome === "refused" ? "content_refused" : "wrong_language",
    );
  }

  const { error: completionError } = await admin.rpc("complete_correction", {
    p_entry_id: entryId,
    p_corrected_text: result.correctedText,
    p_items: result.items,
    p_model: result.usage.model,
    p_input_tokens: result.usage.inputTokens,
    p_output_tokens: result.usage.outputTokens,
  });
  if (completionError) {
    console.error("Correction non enregistrée", completionError.message);
    await recordUsage(userId, result.usage);
    return releaseAndRespond(entryId, 503, "ai_unavailable");
  }

  return json(200, await loadEntry(entryId));
});
