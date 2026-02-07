const DEFAULT_TIMEOUT_MS = 5000;

async function headOrGet(url, timeoutMs) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const headResponse = await fetch(url, {
      method: 'HEAD',
      redirect: 'follow',
      signal: controller.signal
    });

    if (headResponse.status !== 405 && headResponse.status !== 403) {
      return headResponse;
    }

    const getResponse = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: {
        Range: 'bytes=0-1024'
      }
    });
    return getResponse;
  } finally {
    clearTimeout(timeout);
  }
}

function classifyReachability(response) {
  if (!response) {
    return false;
  }

  if (response.status >= 200 && response.status < 500) {
    return true;
  }

  return false;
}

export async function probeProvidersFromCurrentNetwork(providers, accessStore, options = {}) {
  const timeoutMs = Number(options.timeoutMs) || DEFAULT_TIMEOUT_MS;

  const jobs = providers.map(async (provider) => {
    const startedAt = Date.now();
    let reachable = false;
    let statusCode = null;
    let error = null;

    try {
      const response = await headOrGet(provider.homeUrl, timeoutMs);
      statusCode = response.status;
      reachable = classifyReachability(response);
    } catch (err) {
      reachable = false;
      error = err instanceof Error ? err.message : 'probe failed';
    }

    const latencyMs = Date.now() - startedAt;

    await accessStore.recordProbeResult(provider, {
      reachable,
      latencyMs,
      source: 'network-probe'
    });

    return {
      providerId: provider.id,
      providerName: provider.name,
      providerKind: provider.kind,
      homeUrl: provider.homeUrl,
      reachable,
      latencyMs,
      statusCode,
      error,
      snapshot: accessStore.getSnapshot(provider.id, provider.kind)
    };
  });

  return Promise.all(jobs);
}
