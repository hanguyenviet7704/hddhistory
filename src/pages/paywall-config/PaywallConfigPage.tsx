// Admin editor for `paywall_config`, now stored in MySQL (append-only,
// versioned) instead of Firebase Remote Config -- see
// meup-api/src/modules/paywall-config for the source of truth. Job: an
// operator reviews/edits the sale strategies (default user / new user / sale
// event) and publishes. There is no environment switch anymore: each
// deployment's API only ever reads/writes its own database, so dev vs prod
// is the deployment itself, not a toggle on this page. Version history
// (previously free from the Remote Config console) lives in the drawer
// opened from "History".
//
// Client-side validation in `paywallConfigDraft.ts` mirrors
// `PaywallConfigService.validateShape` + `assertProductsExist` field-for-
// field (same `field` path strings the backend uses) so inline errors work
// immediately, without depending on a round trip. That matters today
// because the shared `AllExceptionsFilter` + `BaseValidationPipe` in
// meup-api collapse the backend's structured `errors` array down to a
// single message string before it ever reaches the browser -- see
// `paywallConfigApiErrors.ts` for the full note. This page still reads
// `err.response.data.errors` defensively so a future backend fix lights up
// automatically.
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowPathIcon,
  CheckCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  RocketLaunchIcon,
} from "@heroicons/react/24/outline";
import { useActivePaywallProducts } from "../../components/paywall-config/useActivePaywallProducts";
import ConfirmDialog from "../../components/paywall-config/ConfirmDialog";
import { paywallConfigService } from "../../services/paywallConfigService";
import {
  PaywallConfigResponse,
  PaywallConfigVersion,
} from "../../types/interface/paywall-config.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  extractErrorMessage,
  extractFieldErrors,
  isNotFound,
} from "./paywallConfigApiErrors";
import {
  ConfigDraft,
  defaultDraft,
  fromDraft,
  hasAnyError,
  toDraft,
  validateDraft,
} from "./paywallConfigDraft";
import DefaultUserSection from "./components/DefaultUserSection";
import GeneralSection from "./components/GeneralSection";
import NewUserSection from "./components/NewUserSection";
import SaleEventSection from "./components/SaleEventSection";
import VersionHistoryDrawer from "./components/VersionHistoryDrawer";
import VersionInfoPanel from "./components/VersionInfoPanel";

interface VersionMeta {
  version: PaywallConfigResponse["version"];
  publishedAt: PaywallConfigResponse["publishedAt"];
  publishedBy: PaywallConfigResponse["publishedBy"];
}

const unwrap = <T,>(payload: any): T => payload?.data ?? payload;

export default function PaywallConfigPage() {
  const { showSuccess, showError } = useNotification();

  const [draft, setDraft] = useState<ConfigDraft | null>(null);
  const [savedSnapshot, setSavedSnapshot] = useState<string | null>(null);
  const [versionMeta, setVersionMeta] = useState<VersionMeta | null>(null);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const [confirmPublishOpen, setConfirmPublishOpen] = useState(false);

  const [historyOpen, setHistoryOpen] = useState(false);
  const [versions, setVersions] = useState<PaywallConfigVersion[] | null>(null);
  const [versionsLoading, setVersionsLoading] = useState(false);
  const [versionsError, setVersionsError] = useState<string | null>(null);
  const [restoreTarget, setRestoreTarget] = useState<PaywallConfigVersion | null>(null);
  const [restoringVersion, setRestoringVersion] = useState<number | null>(null);

  const {
    productsByPlatform,
    loading: productsLoading,
    error: productsError,
    refetch: refetchProducts,
  } = useActivePaywallProducts();

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    setNotFound(false);
    setFieldErrors({});
    try {
      const envelope = await paywallConfigService.getConfig();
      const payload = unwrap<PaywallConfigResponse>(envelope);
      const newDraft = toDraft(payload.config);
      setDraft(newDraft);
      setSavedSnapshot(JSON.stringify(newDraft));
      setVersionMeta({
        version: payload.version,
        publishedAt: payload.publishedAt,
        publishedBy: payload.publishedBy,
      });
    } catch (err: any) {
      if (isNotFound(err)) {
        setNotFound(true);
        setDraft(null);
        setSavedSnapshot(null);
        setVersionMeta(null);
      } else {
        const message = extractErrorMessage(err, "Failed to load paywall config");
        setLoadError(message);
        showError(message);
      }
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const isDirty = useMemo(() => {
    if (!draft) return false;
    if (savedSnapshot === null) return true; // started from defaults, never saved
    return JSON.stringify(draft) !== savedSnapshot;
  }, [draft, savedSnapshot]);

  useEffect(() => {
    const handler = (e: BeforeUnloadEvent) => {
      if (isDirty) {
        e.preventDefault();
        e.returnValue = "";
      }
    };
    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, [isDirty]);

  const handleStartFromDefaults = () => {
    setNotFound(false);
    setDraft(defaultDraft());
    setSavedSnapshot(null);
    setFieldErrors({});
  };

  const patchDraft = (patch: Partial<ConfigDraft>) =>
    setDraft((prev) => (prev ? { ...prev, ...patch } : prev));

  const handlePublishClick = () => {
    if (!draft || loading || saving || productsLoading) return;
    const errors = validateDraft(draft, productsByPlatform);
    setFieldErrors(errors);
    if (hasAnyError(errors)) {
      showError("Fix the highlighted fields before publishing.");
      return;
    }
    setConfirmPublishOpen(true);
  };

  const handleConfirmPublish = async () => {
    if (!draft) return;
    setSaving(true);
    try {
      const payload = fromDraft(draft);
      const envelope = await paywallConfigService.updateConfig(payload);
      const data = unwrap<PaywallConfigResponse>(envelope);
      const newDraft = toDraft(data.config);
      setDraft(newDraft);
      setSavedSnapshot(JSON.stringify(newDraft));
      setVersionMeta({
        version: data.version,
        publishedAt: data.publishedAt,
        publishedBy: data.publishedBy,
      });
      setFieldErrors({});
      setNotFound(false);
      showSuccess(`Published paywall config (version ${data.version}).`);
    } catch (err: any) {
      setFieldErrors(extractFieldErrors(err));
      showError(extractErrorMessage(err, "Failed to publish paywall config"));
    } finally {
      setSaving(false);
      setConfirmPublishOpen(false);
    }
  };

  const loadVersions = useCallback(async () => {
    setVersionsLoading(true);
    setVersionsError(null);
    try {
      const envelope = await paywallConfigService.getVersions();
      const rows = unwrap<PaywallConfigVersion[]>(envelope);
      setVersions(rows ?? []);
    } catch (err: any) {
      setVersionsError(extractErrorMessage(err, "Failed to load version history"));
    } finally {
      setVersionsLoading(false);
    }
  }, []);

  const handleOpenHistory = () => {
    setHistoryOpen(true);
    loadVersions();
  };

  const handleRequestRestore = (entry: PaywallConfigVersion) => {
    if (entry.isCurrent || restoringVersion !== null) return;
    setRestoreTarget(entry);
  };

  const handleConfirmRestore = async () => {
    if (!restoreTarget) return;
    const target = restoreTarget;
    setRestoringVersion(target.version);
    try {
      const envelope = await paywallConfigService.restoreVersion(target.version);
      const data = unwrap<PaywallConfigResponse>(envelope);
      const newDraft = toDraft(data.config);
      setDraft(newDraft);
      setSavedSnapshot(JSON.stringify(newDraft));
      setVersionMeta({
        version: data.version,
        publishedAt: data.publishedAt,
        publishedBy: data.publishedBy,
      });
      setFieldErrors({});
      setNotFound(false);
      showSuccess(
        `Restored version ${target.version} as the new live version (version ${data.version}).`
      );
      loadVersions();
    } catch (err: any) {
      showError(extractErrorMessage(err, "Failed to restore this version"));
    } finally {
      setRestoringVersion(null);
      setRestoreTarget(null);
    }
  };

  const errorEntries = Object.entries(fieldErrors);
  const disabled = loading || saving;

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-4">
      <div className="sticky top-0 z-10 bg-slate-50/95 backdrop-blur pb-3 space-y-3">
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <div>
            <h1 className="text-xl font-semibold text-slate-900">Paywall Config</h1>
            <p className="text-xs text-slate-500">
              Edit the <code className="font-mono">paywall_config</code> value the
              mobile paywall reads. Publishing goes live immediately - there is no
              staging step.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => load()}
              disabled={disabled}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
            >
              <ArrowPathIcon className={`h-5 w-5 ${loading ? "animate-spin" : ""}`} />
              Reload
            </button>
            <button
              type="button"
              onClick={handleOpenHistory}
              disabled={loading}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
            >
              <ClockIcon className="h-5 w-5" />
              History
            </button>
            <button
              type="button"
              onClick={handlePublishClick}
              disabled={disabled || !draft || productsLoading}
              className="min-w-[160px] justify-center inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600 disabled:opacity-60"
            >
              {saving ? (
                <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
              ) : (
                <RocketLaunchIcon className="h-5 w-5" />
              )}
              Publish changes
            </button>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className="h-40 rounded-2xl border border-slate-100 bg-slate-100 animate-pulse"
            />
          ))}
        </div>
      ) : loadError ? (
        <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-8 text-center space-y-3">
          <ExclamationTriangleIcon className="h-8 w-8 text-red-500 mx-auto" />
          <p className="text-sm text-red-700">{loadError}</p>
          <button
            type="button"
            onClick={() => load()}
            className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50"
          >
            Retry
          </button>
        </div>
      ) : notFound && !draft ? (
        <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-8 text-center space-y-3">
          <ExclamationTriangleIcon className="h-8 w-8 text-amber-500 mx-auto" />
          <p className="text-sm font-medium text-slate-800">
            No paywall_config published yet.
          </p>
          <p className="text-xs text-slate-500">
            Fill in the fields below and publish to create it.
          </p>
          <button
            type="button"
            onClick={handleStartFromDefaults}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600"
          >
            Start from defaults
          </button>
        </div>
      ) : draft ? (
        <>
          {versionMeta && (
            <VersionInfoPanel
              version={versionMeta.version}
              publishedAt={versionMeta.publishedAt}
              publishedBy={versionMeta.publishedBy}
            />
          )}

          {isDirty && (
            <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
              <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
              Unsaved changes - publish to make them live.
            </div>
          )}

          {errorEntries.length > 0 && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 space-y-1">
              <p className="text-xs font-semibold text-red-800 flex items-center gap-1.5">
                <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
                Validation failed - fix the highlighted fields:
              </p>
              {errorEntries.map(([field, message]) => (
                <p key={field} className="text-xs text-red-700 pl-5">
                  <code className="font-mono text-[11px] text-red-800">{field}</code>: {message}
                </p>
              ))}
            </div>
          )}

          <GeneralSection
            draft={draft}
            onChange={patchDraft}
            disabled={disabled}
            fieldErrors={fieldErrors}
          />

          <DefaultUserSection
            value={draft.defaultUser}
            onChange={(defaultUser) => patchDraft({ defaultUser })}
            disabled={disabled}
            fieldErrors={fieldErrors}
            productsByPlatform={productsByPlatform}
            productsLoading={productsLoading}
            productsError={productsError}
            onRefreshProducts={refetchProducts}
          />

          <NewUserSection
            value={draft.newUser}
            onChange={(newUser) => patchDraft({ newUser })}
            disabled={disabled}
            fieldErrors={fieldErrors}
            productsByPlatform={productsByPlatform}
            productsLoading={productsLoading}
            productsError={productsError}
            onRefreshProducts={refetchProducts}
          />

          <SaleEventSection
            value={draft.saleEvent}
            onChange={(saleEvent) => patchDraft({ saleEvent })}
            disabled={disabled}
            fieldErrors={fieldErrors}
            productsByPlatform={productsByPlatform}
            productsLoading={productsLoading}
            productsError={productsError}
            onRefreshProducts={refetchProducts}
          />
        </>
      ) : null}

      <ConfirmDialog
        open={confirmPublishOpen}
        title="Publish these changes?"
        message={
          <>
            This becomes the live <code className="font-mono">paywall_config</code>{" "}
            immediately - every app on this deployment reads it on its next fetch.
            There is no staging step.
          </>
        }
        confirmLabel={saving ? "Publishing..." : "Publish"}
        loading={saving}
        onConfirm={handleConfirmPublish}
        onCancel={() => setConfirmPublishOpen(false)}
      />

      <ConfirmDialog
        open={Boolean(restoreTarget)}
        title={`Restore version ${restoreTarget?.version}?`}
        message={
          <>
            This republishes version {restoreTarget?.version}'s config as a new
            version and makes it live immediately, replacing what's currently
            published.
          </>
        }
        confirmLabel={restoringVersion !== null ? "Restoring..." : "Restore"}
        tone="danger"
        loading={restoringVersion !== null}
        onConfirm={handleConfirmRestore}
        onCancel={() => setRestoreTarget(null)}
      />

      <VersionHistoryDrawer
        open={historyOpen}
        versions={versions}
        loading={versionsLoading}
        error={versionsError}
        restoringVersion={restoringVersion}
        onRetry={loadVersions}
        onRestore={handleRequestRestore}
        onClose={() => setHistoryOpen(false)}
      />

      {!loading && !loadError && draft && !isDirty && errorEntries.length === 0 && versionMeta && (
        <div className="flex items-center gap-1.5 text-xs text-emerald-700">
          <CheckCircleIcon className="h-4 w-4" />
          Up to date with the live config (version {versionMeta.version}).
        </div>
      )}
    </div>
  );
}
