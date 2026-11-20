// GET /functions/v1/admob-reward — rappel d'AdMob quand une vidéo récompensée a été vue en
// entier (US-23). Seul ce rappel, signé par Google, accorde la récompense : l'app ne peut pas
// se l'attribuer. L'app transmet l'identifiant de l'utilisateur (user_id) et la récompense
// choisie (custom_data : « correction » ou « exercises ») à AdMob.
import { admin, json, UUID_PATTERN } from "../_shared/http.ts";
import { signedParts, type VerifierKey, verifySsv } from "./verify.ts";

const KEYS_URL = Deno.env.get("ADMOB_VERIFIER_KEYS_URL") ??
  "https://gstatic.com/admob/reward/verifier-keys.json";
// Identifiants (numériques) des blocs de vidéos récompensées de l'app. Les clés d'AdMob sont
// communes à toutes les apps : sans ce filtre, une autre app pourrait viser cette adresse.
const REWARDED_AD_UNITS = (Deno.env.get("ADMOB_REWARDED_AD_UNITS") ?? "")
  .split(",").map((unit) => unit.trim()).filter((unit) => unit !== "");
const KEYS_LIFETIME_MS = 24 * 60 * 60 * 1000;
// Rechargement forcé (clé inconnue) au plus une fois par minute : une requête forgée en
// boucle ne déclenche pas autant d'appels à Google.
const MIN_REFRESH_INTERVAL_MS = 60 * 1000;
const KEYS_FETCH_TIMEOUT_MS = 5000;
const REWARD_KINDS = ["correction", "exercises"];

let cachedKeys: { keys: VerifierKey[]; fetchedAt: number } | null = null;

/** Clés de vérification d'AdMob ; rechargées si [keyId] est inconnu (rotation des clés). */
async function verifierKeys(keyId: number | undefined): Promise<VerifierKey[]> {
  const age = cachedKeys ? Date.now() - cachedKeys.fetchedAt : Infinity;
  const isKnown = cachedKeys?.keys.some((key) => key.keyId === keyId) ?? false;
  if (cachedKeys && age < KEYS_LIFETIME_MS && (isKnown || age < MIN_REFRESH_INTERVAL_MS)) {
    return cachedKeys.keys;
  }
  const response = await fetch(KEYS_URL, { signal: AbortSignal.timeout(KEYS_FETCH_TIMEOUT_MS) });
  if (!response.ok) throw new Error(`Clés AdMob indisponibles (${response.status})`);
  const { keys } = await response.json() as { keys: VerifierKey[] };
  cachedKeys = { keys, fetchedAt: Date.now() };
  return keys;
}

Deno.serve(async (request) => {
  if (request.method !== "GET") return json(405, { error: "method_not_allowed" });

  const rawQuery = new URL(request.url).search.slice(1);
  // La console AdMob envoie une requête sans signature quand on enregistre l'adresse.
  if (!rawQuery.includes("signature=")) return json(200, { status: "ignored" });

  let isAuthentic: boolean;
  try {
    isAuthentic = await verifySsv(rawQuery, await verifierKeys(signedParts(rawQuery)?.keyId));
  } catch (error) {
    console.error("Vérification AdMob impossible", error instanceof Error ? error.message : error);
    // Une réponse 5xx fait réessayer AdMob plus tard.
    return json(503, { error: "verification_unavailable" });
  }
  if (!isAuthentic) return json(401, { error: "invalid_signature" });

  const params = new URLSearchParams(rawQuery);
  const adUnit = params.get("ad_unit") ?? "";
  const userId = params.get("user_id") ?? "";
  const kind = params.get("custom_data") ?? "";
  const transactionId = params.get("transaction_id") ?? "";
  if (
    (REWARDED_AD_UNITS.length > 0 && !REWARDED_AD_UNITS.includes(adUnit)) ||
    !UUID_PATTERN.test(userId) || !REWARD_KINDS.includes(kind) || transactionId === ""
  ) {
    return json(200, { status: "ignored" });
  }

  const { data: status, error } = await admin.rpc("grant_ad_reward", {
    p_transaction_id: transactionId,
    p_user_id: userId,
    p_kind: kind,
  });
  if (error) {
    console.error("Récompense non accordée", transactionId, error.message);
    return json(500, { error: "internal" });
  }
  return json(200, { status });
});
