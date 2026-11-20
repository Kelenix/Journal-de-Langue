// Socle commun des Edge Functions appelées par l'app : client serveur, identité de
// l'appelant, réponses JSON, valeurs acceptées en entrée.
import { createClient } from "npm:@supabase/supabase-js@2.119.2";

export const LANGUAGES = ["en", "es", "de", "fr"] as const;
export const UI_LOCALES = ["fr", "en"] as const;
export type Language = (typeof LANGUAGES)[number];
export type UiLocale = (typeof UI_LOCALES)[number];

export const LANGUAGE_NAMES: Record<Language, string> = {
  en: "English",
  es: "Spanish",
  de: "German",
  fr: "French",
};

export const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

/** Jour calendaire « AAAA-MM-JJ » qui existe : « 2026-02-30 » est refusé. */
export function isLocalDate(value: unknown): value is string {
  return typeof value === "string" && DATE_PATTERN.test(value) &&
    !Number.isNaN(Date.parse(`${value}T00:00:00Z`)) &&
    new Date(`${value}T00:00:00Z`).toISOString().startsWith(value);
}

/** Client avec le rôle service : n'est jamais exposé à l'app. */
export const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Identifiant de l'utilisateur dont le jeton accompagne la requête, vérifié auprès du serveur d'authentification. */
export async function userIdFrom(request: Request): Promise<string | null> {
  const token = request.headers.get("Authorization")?.replace(/^Bearer /i, "");
  if (!token) return null;
  const { data } = await admin.auth.getUser(token);
  return data.user?.id ?? null;
}

/** Corps JSON de la requête sous forme d'objet, ou `null` s'il est illisible. */
export async function jsonBody(request: Request): Promise<Record<string, unknown> | null> {
  const body = await request.json().catch(() => null);
  return typeof body === "object" && body !== null ? body as Record<string, unknown> : null;
}

export function isLanguage(value: unknown): value is Language {
  return LANGUAGES.includes(value as Language);
}

export function isUiLocale(value: unknown): value is UiLocale {
  return UI_LOCALES.includes(value as UiLocale);
}
