// Admin editor for `paywall_config`, a Firebase Remote Config value the
// Flutter paywall reads directly. Job: an operator reviews/edits the sale
// strategies (default user / new user / sale event) and publishes -- there
// is no list, this always edits the single config for whichever environment
// (dev/prod) is currently selected.
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
  ExclamationTriangleIcon,
  RocketLaunchIcon,
} from "@heroicons/react/24/outline";
import { useActivePaywallProducts } from "../../components/paywall-config/useActivePaywallProducts";
import ConfirmDialog from "../../components/paywall-config/ConfirmDialog";
import { paywallConfigService } from "../../services/paywallConfigService";
import { PaywallEnvironment } from "../../types/enum/paywall-config.enum";
import { PaywallConfigResponse } from "../../types/interface/paywall-config.interface";
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
import EnvironmentBar from "./components/EnvironmentBar";
import GeneralSection from "./components/GeneralSection";
import NewUserSection from "./components/NewUserSection";
import SaleEventSection from "./components/SaleEventSection";
import VersionInfoPanel from "./components/VersionInfoPanel";

interface SourceMeta {
  source: PaywallConfigResponse["source"];
  version: PaywallConfigResponse["version"];
}

const unwrap = (payload: any): PaywallConfigResponse => payload?.data ?? payload;

export default function PaywallConfigPage() {
  const { showSuccess, showError } = useNotification();

  const [environment, setEnvironment] = useState<PaywallEnvironment>(
    PaywallEnvironment.DEV
  );
  const [draft, setDraft] = useState<ConfigDraft | null>(null);
  const [savedSnapshot, setSavedSnapshot] = useState<string | null>(null);
  const [sourceMeta, setSourceMeta] = useState<SourceMeta | null>(null);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const [pendingSwitchEnv, setPendingSwitchEnv] = useState<PaywallEnvironment | null>(
    null
  );
  const [confirmEnv, setConfirmEnv] = useState<PaywallEnvironment | null>(null);

  const {
    productsByPlatform,
    loading: productsLoading,
    error: productsError,
    refetch: refetchProducts,
  } = useActivePaywallProducts();

  const load = useCallback(
    async (env: PaywallEnvironment) => {
      setLoading(true);
      setLoadError(null);
      setNotFound(false);
      setFieldErrors({});
      try {
        const envelope = await paywallConfigService.getConfig(env);
        const payload = unwrap(envelope);
        const newDraft = toDraft(payload.config);
        setDraft(newDraft);
        setSavedSnapshot(JSON.stringify(newDraft));
        setSourceMeta({ source: payload.source, version: payload.version });
      } catch (err: any) {
        if (isNotFound(err)) {
          setNotFound(true);
          setDraft(null);
          setSavedSnapshot(null);
          setSourceMeta(null);
        } else {
          const message = extractErrorMessage(err, "Failed to load paywall config");
          setLoadError(message);
          showError(message);
        }
      } finally {
        setLoading(false);
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    []
  );

  useEffect(() => {
    load(environment);
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

  const requestSwitchEnvironment = (nextEnv: PaywallEnvironment) => {
    if (nextEnv === environment || loading || saving) return;
    if (isDirty) {
      setPendingSwitchEnv(nextEnv);
    } else {
      setEnvironment(nextEnv);
      load(nextEnv);
    }
  };

  const confirmSwitchEnvironment = () => {
    if (!pendingSwitchEnv) return;
    setEnvironment(pendingSwitchEnv);
    load(pendingSwitchEnv);
    setPendingSwitchEnv(null);
  };

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
    // Snapshot the environment at click time -- the publish call always
    // targets exactly the environment currently displayed, never a value
    // read again later from state that could have drifted.
    setConfirmEnv(environment);
  };

  const handleConfirmPublish = async () => {
    if (!draft || !confirmEnv) return;
    setSaving(true);
    try {
      const payload = fromDraft(draft);
      const envelope = await paywallConfigService.updateConfig(confirmEnv, payload);
      const data = unwrap(envelope);
      const newDraft = toDraft(data.config);
      setDraft(newDraft);
      setSavedSnapshot(JSON.stringify(newDraft));
      setSourceMeta({ source: data.source, version: data.version });
      setFieldErrors({});
      setNotFound(false);
      setConfirmEnv(null);
      showSuccess(`Published paywall config for ${confirmEnv.toUpperCase()}`);
    } catch (err: any) {
      setFieldErrors(extractFieldErrors(err));
      showError(extractErrorMessage(err, "Failed to publish paywall config"));
      setConfirmEnv(null);
    } finally {
      setSaving(false);
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
              Edit the <code className="font-mono">paywall_config</code> Remote
              Config value the mobile paywall reads.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => load(environment)}
              disabled={disabled}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition disabled:opacity-60"
            >
              <ArrowPathIcon className={`h-5 w-5 ${loading ? "animate-spin" : ""}`} />
              Reload
            </button>
            <button
              type="button"
              onClick={handlePublishClick}
              disabled={disabled || !draft || productsLoading}
              className="min-w-[190px] justify-center inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-teal-600 to-emerald-500 text-white shadow hover:from-teal-700 hover:to-emerald-600 disabled:opacity-60"
            >
              {saving ? (
                <span className="h-4 w-4 border-2 border-white/60 border-t-transparent rounded-full animate-spin" />
              ) : (
                <RocketLaunchIcon className="h-5 w-5" />
              )}
              Publish to {environment.toUpperCase()}
            </button>
          </div>
        </div>

        <EnvironmentBar
          environment={environment}
          onSwitch={requestSwitchEnvironment}
          disabled={disabled}
        />
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
            onClick={() => load(environment)}
            className="px-4 py-2 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50"
          >
            Retry
          </button>
        </div>
      ) : notFound && !draft ? (
        <div className="rounded-2xl border border-slate-100 bg-white shadow-sm p-8 text-center space-y-3">
          <ExclamationTriangleIcon className="h-8 w-8 text-amber-500 mx-auto" />
          <p className="text-sm font-medium text-slate-800">
            No paywall_config value published for {environment.toUpperCase()} yet.
          </p>
          <p className="text-xs text-slate-500">
            Fill in the fields below and publish to create it for this environment.
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
          {sourceMeta && (
            <VersionInfoPanel
              environment={environment}
              source={sourceMeta.source}
              version={sourceMeta.version}
            />
          )}

          {isDirty && (
            <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 flex items-center gap-2">
              <ExclamationTriangleIcon className="h-4 w-4 flex-shrink-0" />
              Unsaved changes - publish to apply them to {environment.toUpperCase()}.
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
        open={Boolean(pendingSwitchEnv)}
        title={`Switch to ${pendingSwitchEnv?.toUpperCase()}?`}
        message="You have unsaved changes that will be discarded. This does not affect what's already published."
        confirmLabel="Discard & switch"
        tone="danger"
        onConfirm={confirmSwitchEnvironment}
        onCancel={() => setPendingSwitchEnv(null)}
      />

      <ConfirmDialog
        open={Boolean(confirmEnv)}
        title={
          confirmEnv === PaywallEnvironment.PROD
            ? "Publish to PRODUCTION?"
            : `Publish to ${confirmEnv?.toUpperCase()}?`
        }
        message={
          confirmEnv === PaywallEnvironment.PROD ? (
            <>
              This updates the <code className="font-mono">paywall_config</code>{" "}
              Remote Config value every <strong>production</strong> user reads --
              immediately, with no staging step.
            </>
          ) : (
            <>
              This updates the dev-only Remote Config condition for{" "}
              <code className="font-mono">paywall_config</code>. Only dev-flavor
              apps read this value.
            </>
          )
        }
        confirmLabel={
          saving ? "Publishing..." : `Publish to ${confirmEnv?.toUpperCase()}`
        }
        tone={confirmEnv === PaywallEnvironment.PROD ? "danger" : "default"}
        requireTypedConfirmation={confirmEnv === PaywallEnvironment.PROD ? "PROD" : undefined}
        loading={saving}
        onConfirm={handleConfirmPublish}
        onCancel={() => setConfirmEnv(null)}
      />

      {!loading && !loadError && draft && !isDirty && errorEntries.length === 0 && sourceMeta && (
        <div className="flex items-center gap-1.5 text-xs text-emerald-700">
          <CheckCircleIcon className="h-4 w-4" />
          Up to date with {environment.toUpperCase()}.
        </div>
      )}
    </div>
  );
}
