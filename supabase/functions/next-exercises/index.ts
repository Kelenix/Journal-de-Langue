// POST /functions/v1/next-exercises — prochains exercices de l'utilisateur (US-14).
// Les exercices viennent d'une réserve partagée ; Claude n'est appelé que pour la compléter.
import { z } from "npm:zod@4.6.7";
import { askClaude, errorMessage } from "../_shared/claude.ts";
import {
  admin,
  DATE_PATTERN,
  isLanguage,
  isUiLocale,
  json,
  jsonBody,
  type Language,
  LANGUAGE_NAMES,
  type UiLocale,
  userIdFrom,
} from "../_shared/http.ts";

const MODEL = Deno.env.get("EXERCISE_MODEL") ?? "claude-haiku-5-5";
/** Exercices servis par appel de l'app. */
const BATCH_SIZE = 5;
/** Exercices ajoutés à la réserve par appel à Claude. */
const GENERATED_PER_CALL = 8;

const Generated = z.object({
  exercises: z.array(
    z.object({
      question: z.string(),
      options: z.array(z.string()),
      answer_index: z.number(),
      explanation: z.string(),
    }),
  ),
});

// Clés : valeurs de l'énumération `error_category` en base.
const CATEGORY_FOCUS: Record<string, string> = {
  spelling: "spelling of common words",
  grammar: "grammar: agreement, articles, prepositions, word order",
  conjugation: "verb conjugation and choice of tense",
  vocabulary: "choosing the right word in context",
  register: "choosing wording that fits the situation (formal or informal)",
  phrasing: "natural, idiomatic phrasing",
  punctuation: "punctuation and capitalisation",
};

function systemPrompt(language: Language, uiLocale: UiLocale, category: string): string {
  const target = LANGUAGE_NAMES[language];
  const instructions = LANGUAGE_NAMES[uiLocale];
  return `You write practice exercises for beginner and intermediate learners of ${target}.

Write ${GENERATED_PER_CALL} multiple-choice exercises on: ${CATEGORY_FOCUS[category]}.

For each exercise:
- question: a short instruction in ${instructions}, followed by a sentence in ${target} with a blank written "___", or a request to pick the correct sentence.
- options: exactly 4 answers in ${target}, only one of them correct, the wrong ones being mistakes learners really make.
- answer_index: position of the correct answer, from 0 to 3. Vary it from one exercise to the next.
- explanation: one or two sentences in ${instructions} saying why the correct answer is right. Address the learner informally (in French, use "tu").

Make the exercises different from one another, self-contained, and about everyday situations.`;
}

function pick(userId: string, language: Language, uiLocale: UiLocale, localDate: string) {
  return admin.rpc("pick_exercises", {
    p_user_id: userId,
    p_language: language,
    p_ui_locale: uiLocale,
    p_attempt_date: localDate,
    p_count: BATCH_SIZE,
  });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json(405, { error: "method_not_allowed" });

  const userId = await userIdFrom(request);
  if (!userId) return json(401, { error: "unauthorized" });

  const body = await jsonBody(request);
  const language = body?.language;
  const uiLocale = body?.ui_locale;
  const localDate = body?.local_date;
  if (
    !isLanguage(language) || !isUiLocale(uiLocale) ||
    typeof localDate !== "string" || !DATE_PATTERN.test(localDate)
  ) {
    return json(400, { error: "invalid_input" });
  }

  let { data: picked, error } = await pick(userId, language, uiLocale, localDate);

  if (!error && picked.status === "need_generation") {
    let answer;
    try {
      answer = await askClaude({
        model: MODEL,
        effort: "low",
        maxTokens: 6000,
        system: systemPrompt(language, uiLocale, picked.category),
        input: { count: GENERATED_PER_CALL },
        schema: Generated,
      });
    } catch (generationError) {
      console.error("Génération d'exercices en échec", errorMessage(generationError));
      return json(503, { error: "ai_unavailable" });
    }
    if (answer.outcome === "refused") return json(503, { error: "ai_unavailable" });

    const { error: addError } = await admin.rpc("add_exercises", {
      p_user_id: userId,
      p_language: language,
      p_category: picked.category,
      p_ui_locale: uiLocale,
      p_exercises: answer.data.exercises,
      p_model: answer.usage.model,
      p_input_tokens: answer.usage.inputTokens,
      p_output_tokens: answer.usage.outputTokens,
    });
    if (addError) {
      console.error("Exercices non ajoutés à la réserve", addError.message);
      return json(500, { error: "internal" });
    }
    ({ data: picked, error } = await pick(userId, language, uiLocale, localDate));
  }

  if (error) {
    console.error("Choix des exercices impossible", error.message);
    return json(500, { error: "internal" });
  }
  if (picked.status === "denied") return json(403, { error: picked.reason });
  // La génération n'a pas suffi à constituer la réserve (réponses mal formées).
  if (picked.status === "need_generation") return json(503, { error: "ai_unavailable" });

  return json(200, picked);
});
