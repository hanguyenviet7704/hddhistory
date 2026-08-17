import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";

import { IDashboardQuery } from "../../types/interface/dashboard.interface";

const DAY_MS = 24 * 60 * 60 * 1000;

export const RANGE_PRESETS = [
  { key: "7", label: "7 ngày", days: 7 },
  { key: "30", label: "30 ngày", days: 30 },
  { key: "90", label: "90 ngày", days: 90 },
] as const;

export const APP_ENVS = ["prod", "stg", "dev"] as const;

/** YYYY-MM-DD in local time — never `toISOString`, which silently shifts a day. */
export const toDateInput = (date: Date): string =>
  date.toLocaleDateString("en-CA");

const startOfDay = (value: string): Date => new Date(`${value}T00:00:00`);
const endOfDay = (value: string): Date => new Date(`${value}T23:59:59.999`);

export interface DashboardFilters {
  from: string;
  to: string;
  appEnv: string;
  platform: string;
  appVersion: string;
}

const defaultFilters = (): DashboardFilters => {
  const to = new Date();
  const from = new Date(to.getTime() - 6 * DAY_MS);
  return {
    from: toDateInput(from),
    to: toDateInput(to),
    // Production only by default: our own dev traffic would otherwise be mixed
    // into every product number on the page.
    appEnv: "prod",
    platform: "",
    appVersion: "",
  };
};

/**
 * Dashboard filters, stored in the URL.
 *
 * The query string is the source of truth so the period survives switching
 * between the five dashboard pages, and so a link pasted into chat opens on the
 * same period the sender was looking at.
 */
export const useDashboardFilters = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  const filters = useMemo<DashboardFilters>(() => {
    const fallback = defaultFilters();
    return {
      from: searchParams.get("from") || fallback.from,
      to: searchParams.get("to") || fallback.to,
      appEnv: searchParams.get("env") || fallback.appEnv,
      platform: searchParams.get("platform") || "",
      appVersion: searchParams.get("version") || "",
    };
  }, [searchParams]);

  const setFilters = useCallback(
    (next: Partial<DashboardFilters>) => {
      const merged = { ...filters, ...next };
      const params: Record<string, string> = {
        from: merged.from,
        to: merged.to,
        env: merged.appEnv,
      };
      if (merged.platform) params.platform = merged.platform;
      if (merged.appVersion) params.version = merged.appVersion;
      setSearchParams(params, { replace: true });
    },
    [filters, setSearchParams]
  );

  const applyPreset = useCallback(
    (days: number) => {
      const to = new Date();
      const from = new Date(to.getTime() - (days - 1) * DAY_MS);
      setFilters({ from: toDateInput(from), to: toDateInput(to) });
    },
    [setFilters]
  );

  /** Which preset the current range matches, if any — for the active pill. */
  const activePreset = useMemo(() => {
    const spanDays =
      Math.round(
        (startOfDay(filters.to).getTime() - startOfDay(filters.from).getTime()) /
          DAY_MS
      ) + 1;
    const isToday = filters.to === toDateInput(new Date());
    return isToday
      ? RANGE_PRESETS.find((preset) => preset.days === spanDays)?.key ?? null
      : null;
  }, [filters.from, filters.to]);

  const query = useMemo<IDashboardQuery>(
    () => ({
      from: startOfDay(filters.from).toISOString(),
      to: endOfDay(filters.to).toISOString(),
      appEnv: filters.appEnv,
      platform: filters.platform || undefined,
      appVersion: filters.appVersion || undefined,
    }),
    [filters]
  );

  return { filters, setFilters, applyPreset, activePreset, query };
};

interface DashboardDataState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
}

/**
 * Fetches one dashboard page.
 *
 * Keeps the previous payload on screen while a new period loads (no flash back
 * to a skeleton on every filter tweak), and drops responses that arrive after a
 * newer request — changing the range twice quickly must not leave the older
 * answer on screen.
 */
export const useDashboardData = <T,>(
  fetcher: (query: IDashboardQuery) => Promise<T>,
  query: IDashboardQuery
): DashboardDataState<T> => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [nonce, setNonce] = useState(0);
  const requestId = useRef(0);
  const fetcherRef = useRef(fetcher);
  fetcherRef.current = fetcher;

  const serialized = JSON.stringify(query);

  useEffect(() => {
    const current = ++requestId.current;
    let cancelled = false;

    setLoading(true);
    setError(null);

    fetcherRef
      .current(JSON.parse(serialized))
      .then((result) => {
        if (cancelled || current !== requestId.current) return;
        setData(result);
      })
      .catch((err: any) => {
        if (cancelled || current !== requestId.current) return;
        setError(
          err?.response?.data?.message ||
            err?.message ||
            "Không tải được dữ liệu"
        );
      })
      .finally(() => {
        if (cancelled || current !== requestId.current) return;
        setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [serialized, nonce]);

  const reload = useCallback(() => setNonce((value) => value + 1), []);

  return { data, loading, error, reload };
};
