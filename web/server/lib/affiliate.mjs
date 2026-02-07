function safeUrl(urlString) {
  try {
    return new URL(urlString);
  } catch {
    return null;
  }
}

export function attachAffiliateParams(urlString, provider) {
  const url = safeUrl(urlString);
  if (!url) {
    return urlString;
  }

  const globalCode = process.env.AFFILIATE_GLOBAL_CODE;
  if (globalCode && !url.searchParams.has('utm_source')) {
    url.searchParams.set('utm_source', 'flightfinder-web');
    url.searchParams.set('utm_medium', 'affiliate');
    url.searchParams.set('utm_campaign', globalCode);
  }

  const providerParams = Array.isArray(provider.affiliateParams) ? provider.affiliateParams : [];
  for (const entry of providerParams) {
    const value = process.env[entry.env] ?? entry.defaultValue;
    if (value && !url.searchParams.has(entry.param)) {
      url.searchParams.set(entry.param, value);
    }
  }

  return url.toString();
}
