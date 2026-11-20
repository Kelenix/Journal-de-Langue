// Vérification des rappels AdMob, avec une paire de clés créée pour le test.
// Lancer : deno test supabase/functions/admob-reward/verify_test.ts
import { assert, assertEquals } from "jsr:@std/assert@1";
import { derToRaw, verifySsv, type VerifierKey } from "./verify.ts";

const KEY_ID = 3335741209;

function toBase64Url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_")
    .replace(/=+$/, "");
}

/** Signature brute r || s → DER, comme la produit AdMob. */
function rawToDer(raw: Uint8Array): Uint8Array {
  const integer = (value: Uint8Array) => {
    let start = 0;
    while (start < value.length - 1 && value[start] === 0) start++;
    const trimmed = value.slice(start);
    const bytes = trimmed[0] & 0x80 ? [0, ...trimmed] : [...trimmed];
    return [0x02, bytes.length, ...bytes];
  };
  const body = [...integer(raw.slice(0, 32)), ...integer(raw.slice(32))];
  return Uint8Array.from([0x30, body.length, ...body]);
}

async function signedQuery(message: string, keys: CryptoKeyPair): Promise<string> {
  const raw = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      keys.privateKey,
      new TextEncoder().encode(message),
    ),
  );
  return `${message}&signature=${toBase64Url(rawToDer(raw))}&key_id=${KEY_ID}`;
}

async function setUp(): Promise<{ keys: CryptoKeyPair; published: VerifierKey[] }> {
  const keys = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  );
  const spki = new Uint8Array(await crypto.subtle.exportKey("spki", keys.publicKey));
  return { keys, published: [{ keyId: KEY_ID, base64: btoa(String.fromCharCode(...spki)) }] };
}

const MESSAGE = "ad_network=5450213213286189855&ad_unit=1234567890&custom_data=correction" +
  "&reward_amount=1&reward_item=correction&timestamp=1763548800000" +
  "&transaction_id=123456789&user_id=00000000-0000-0000-0000-00000000000a";

Deno.test("un rappel signé par AdMob est accepté", async () => {
  const { keys, published } = await setUp();
  assert(await verifySsv(await signedQuery(MESSAGE, keys), published));
});

Deno.test("un rappel modifié (autre utilisateur) est refusé", async () => {
  const { keys, published } = await setUp();
  const query = await signedQuery(MESSAGE, keys);
  const tampered = query.replace("00000000-0000-0000-0000-00000000000a", "00000000-0000-0000-0000-00000000000b");
  assertEquals(await verifySsv(tampered, published), false);
});

Deno.test("une clé inconnue ou une requête sans signature est refusée", async () => {
  const { keys, published } = await setUp();
  const query = await signedQuery(MESSAGE, keys);
  assertEquals(await verifySsv(query.replace(`key_id=${KEY_ID}`, "key_id=1"), published), false);
  assertEquals(await verifySsv(MESSAGE, published), false);
});

Deno.test("une signature d'une autre clé est refusée", async () => {
  const { published } = await setUp();
  const other = await setUp();
  assertEquals(await verifySsv(await signedQuery(MESSAGE, other.keys), published), false);
});

Deno.test("les coordonnées courtes ou précédées d'un zéro sont ramenées à 32 octets", () => {
  const raw = new Uint8Array(64);
  raw[31] = 7; // r petit
  raw[32] = 0x80; // s avec le bit de poids fort : zéro de tête en DER
  assertEquals(derToRaw(rawToDer(raw)), raw);
});
