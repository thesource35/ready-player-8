"use client";
import { useState, useEffect } from "react";

interface UseFetchResult<T> {
  data: T | null;
  isLoading: boolean;
  error: string | null;
  refetch: () => void;
}

/**
 * Shared fetch hook — eliminates duplicate fetch+setState patterns across pages.
 * Falls back to provided default data on error.
 */
export function useFetch<T>(
  url: string,
  defaultData: T | null = null,
  transform?: (raw: unknown) => T
): UseFetchResult<T> {
  const [data, setData] = useState<T | null>(defaultData);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [trigger, setTrigger] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    setError(null);

    fetch(url)
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then(raw => {
        if (cancelled) return;
        const result = transform ? transform(raw) : (raw as T);
        setData(result);
        setIsLoading(false);
      })
      .catch(err => {
        if (cancelled) return;
        console.error(`[useFetch] ${url} failed:`, err.message);
        setError(`Failed to load data`);
        setIsLoading(false);
      });

    return () => { cancelled = true; };
  }, [url, trigger]); // eslint-disable-line react-hooks/exhaustive-deps

  const refetch = () => setTrigger(t => t + 1);

  return { data, isLoading, error, refetch };
}
