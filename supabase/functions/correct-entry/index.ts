// POST /functions/v1/correct-entry — corrige le journal du jour (US-05 à US-07, US-12).
// Le quota est réservé en base avant l'appel à Claude et rendu si la correction échoue.
import { errorMessage, recordUsage } from "../_shared/claude.ts";
import {
  admin,
  DATE_PATTERN,
  isLanguage,
  isUiLocale,
  json,
  jsonBody,
  type Language,
  type UiLocale,
  userIdFrom,
  UUID_PATTERN,
} from "../_shared/http.ts";
import { correctEntry, type Level } from "./corrector.ts";

// Garde-fou large contre les requêtes abusives ; la limite de l'offre est appliquée en base.
const MAX_TEXT_LENGTH = 10_000;

interface CorrectionRequest {
  text: string;
  language: Language;
  uiLocale: UiLocale;
  localDate: string;
  idempotencyKey: string;
}

function parseRequest(body: Record<string, unknown> | null): CorrectionRequest | null {
  if (!body) return null;
  const { text, language, ui_locale, local_date, idempotency_key } = body;
  const isValid = typeof text === "string" && text.length <= MAX_TEXT_LENGTH &&
    isLanguage(language) && isUiLocale(ui_locale) &&
    typeof local_date === "string" && DATE_PATTERN.test(local_date) &&
    typeof idempotency_key === "string" && UUID_PATTERN.test(idempotency_key);
  if (!isValid) return null;
  return {
    text,
    language,
    uiLocale: ui_locale,
    localDate: local_date,
    idempotencyKey: idempotency_key,
  };
}

async function loadEntry(entryId: string): Promise<unknown> {
  const { data, error } = await admin
    .from("journal_entries")
    .select(
      "id, language, entry_date, original_text, corrected_text, level, " +
        "correction_items(position, original, corrected, category, explanation), " +
        "vocabulary_items(id, term, translation, example, learned_at)",
    )
    .eq("id", entryId)
    .order("position", { referencedTable: "correction_items" })
    .order("created_at", { referencedTable: "vocabulary_items" })
    .order("term", { referencedTable: "vocabulary_items" })
    .single();
  if (error) throw error;
  return data;
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

  const input = parseRequest(await jsonBody(request));
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

  const level: Level = reservation.level;
  const feature = `correction_${level}`;
  let result;
  try {
    result = await correctEntry(input.text, input.language, input.uiLocale, level);
  } catch (error) {
    // Jamais le texte du journal dans les journaux techniques.
    console.error("Correction IA en échec", errorMessage(error));
    return releaseAndRespond(entryId, 503, "ai_unavailable");
  }

  if (result.outcome !== "corrected") {
    await recordUsage(userId, feature, result.usage);
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
    p_vocabulary: result.vocabulary,
    p_model: result.usage.model,
    p_input_tokens: result.usage.inputTokens,
    p_output_tokens: result.usage.outputTokens,
  });
  if (completionError) {
    console.error("Correction non enregistrée", completionError.message);
    await recordUsage(userId, feature, result.usage);
    return releaseAndRespond(entryId, 503, "ai_unavailable");
  }

  return json(200, await loadEntry(entryId));
});
