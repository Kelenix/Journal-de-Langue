// Appel à Claude avec une réponse structurée, validée par un schéma.
import Anthropic from "npm:@anthropic-ai/sdk@1.10.0";
import { zodOutputFormat } from "npm:@anthropic-ai/sdk@1.10.0/helpers/zod";
import type { z } from "npm:zod@4.6.7";
import { admin } from "./http.ts";

export interface Usage {
  model: string;
  inputTokens: number;
  outputTokens: number;
}

export type Answer<T> =
  | { outcome: "answered"; data: T; usage: Usage }
  | { outcome: "refused"; usage: Usage };

interface Question<T> {
  model: string;
  effort: "low" | "medium" | "high";
  /** La réflexion du modèle compte dans ce plafond : prévoir de la marge au-delà de la réponse. */
  maxTokens: number;
  system: string;
  /** Données de l'utilisateur, transmises en JSON : elles ne peuvent pas sortir de leur champ. */
  input: unknown;
  schema: z.ZodType<T>;
}

const REQUEST_TIMEOUT_MS = 25_000;

/**
 * Interroge Claude. Lève une erreur si l'API est injoignable ou si sa réponse est
 * inexploitable : l'appelant ne débite alors rien à l'utilisateur.
 */
export async function askClaude<T>(question: Question<T>): Promise<Answer<T>> {
  // Créé à la demande : une clé absente doit produire une erreur gérée, pas empêcher la
  // fonction de démarrer.
  const anthropic = new Anthropic({ maxRetries: 1, timeout: REQUEST_TIMEOUT_MS });

  const response = await anthropic.messages.parse({
    model: question.model,
    max_tokens: question.maxTokens,
    output_config: { effort: question.effort, format: zodOutputFormat(question.schema) },
    system: question.system,
    messages: [{ role: "user", content: JSON.stringify(question.input) }],
  });

  const usage: Usage = {
    model: response.model,
    inputTokens: response.usage.input_tokens,
    outputTokens: response.usage.output_tokens,
  };

  // Refus du modèle (filtre de sécurité) : pas de repli automatique vers un autre modèle,
  // l'utilisateur est simplement informé que ce texte ne peut pas être traité (ADR-023).
  if (response.stop_reason === "refusal") return { outcome: "refused", usage };

  const data = response.parsed_output;
  if (response.stop_reason !== "end_turn" || data == null) {
    throw new Error(`Réponse du modèle inexploitable (stop_reason: ${response.stop_reason})`);
  }
  return { outcome: "answered", data: data as T, usage };
}

/** Journalise le coût d'un appel qui n'a pas abouti à un enregistrement. */
export async function recordUsage(userId: string, feature: string, usage: Usage): Promise<void> {
  const { error } = await admin.from("ai_usage").insert({
    user_id: userId,
    feature,
    model: usage.model,
    input_tokens: usage.inputTokens,
    output_tokens: usage.outputTokens,
  });
  if (error) console.error("Coût IA non journalisé", error.message);
}

/** Message d'erreur sans donnée de l'utilisateur, pour les journaux techniques. */
export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
