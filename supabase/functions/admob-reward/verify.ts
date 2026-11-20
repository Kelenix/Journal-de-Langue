// Vérification des rappels signés d'AdMob pour les vidéos récompensées (SSV).
// https://developers.google.com/admob/android/ssv : « signature » et « key_id » sont les deux
// derniers paramètres ; tout ce qui précède « &signature= » est signé en ECDSA P-256 / SHA-256,
// signature DER encodée en base64 (variante URL).

/** Clé publique d'AdMob, telle que publiée dans verifier-keys.json. */
export interface VerifierKey {
  keyId: number;
  /** Clé publique au format SPKI (DER), en base64. */
  base64: string;
}

const SIGNATURE_MARKER = "&signature=";
const COORDINATE_LENGTH = 32;

/** Message signé, signature et identifiant de clé d'une requête de rappel, ou `null`. */
export function signedParts(
  rawQuery: string,
): { message: string; signature: string; keyId: number } | null {
  const index = rawQuery.indexOf(SIGNATURE_MARKER);
  if (index <= 0) return null;
  const tail = new URLSearchParams(rawQuery.slice(index + 1));
  const signature = tail.get("signature");
  const keyId = Number(tail.get("key_id"));
  if (!signature || !Number.isSafeInteger(keyId)) return null;
  return { message: rawQuery.slice(0, index), signature, keyId };
}

/** Décode du base64, variante URL ou standard, avec ou sans remplissage. */
export function base64ToBytes(value: string): Uint8Array<ArrayBuffer> {
  const standard = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = standard.padEnd(Math.ceil(standard.length / 4) * 4, "=");
  return Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
}

/**
 * Convertit une signature ECDSA DER (SEQUENCE de deux INTEGER) au format attendu par
 * WebCrypto : r et s bout à bout, sur 32 octets chacun.
 */
export function derToRaw(der: Uint8Array): Uint8Array<ArrayBuffer> | null {
  if (der[0] !== 0x30) return null;
  let offset = 2;
  const coordinates: Uint8Array[] = [];
  for (let index = 0; index < 2; index++) {
    if (der[offset] !== 0x02) return null;
    const length = der[offset + 1];
    let value = der.slice(offset + 2, offset + 2 + length);
    offset += 2 + length;
    // Un INTEGER DER peut porter un zéro de tête (signe) ou être plus court que 32 octets.
    while (value.length > COORDINATE_LENGTH && value[0] === 0) value = value.slice(1);
    if (value.length > COORDINATE_LENGTH) return null;
    const padded = new Uint8Array(COORDINATE_LENGTH);
    padded.set(value, COORDINATE_LENGTH - value.length);
    coordinates.push(padded);
  }
  const raw = new Uint8Array(COORDINATE_LENGTH * 2);
  raw.set(coordinates[0], 0);
  raw.set(coordinates[1], COORDINATE_LENGTH);
  return raw;
}

/** Vrai si la requête de rappel est signée par l'une des clés d'AdMob. */
export async function verifySsv(rawQuery: string, keys: VerifierKey[]): Promise<boolean> {
  const parts = signedParts(rawQuery);
  if (!parts) return false;
  const key = keys.find((candidate) => candidate.keyId === parts.keyId);
  if (!key) return false;
  const signature = derToRaw(base64ToBytes(parts.signature));
  if (!signature) return false;

  const publicKey = await crypto.subtle.importKey(
    "spki",
    base64ToBytes(key.base64),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  return crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    publicKey,
    signature,
    new TextEncoder().encode(parts.message),
  );
}
