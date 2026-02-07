export function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

export function toUpperIata(input) {
  const cleaned = String(input ?? '')
    .toUpperCase()
    .replace(/[^A-Z]/g, '')
    .slice(0, 3);
  return cleaned;
}

export function isIsoDate(date) {
  return /^\d{4}-\d{2}-\d{2}$/.test(String(date ?? ''));
}

export function parseDate(date) {
  if (!isIsoDate(date)) {
    return null;
  }
  const parsed = new Date(`${date}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed;
}

export function stableHash(input) {
  const value = String(input);
  let hash = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

export function seededNumber(seed, min, max) {
  const normalized = (seed % 10000) / 10000;
  return min + (max - min) * normalized;
}

export function average(values) {
  if (!values.length) {
    return 0;
  }
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

export function asArray(value) {
  if (Array.isArray(value)) {
    return value;
  }
  return [];
}
