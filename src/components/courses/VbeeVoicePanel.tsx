import React, { useEffect, useMemo, useRef, useState } from "react";
import { Loader2Icon, PauseIcon, PlayIcon, SaveIcon } from "lucide-react";

import {
  VbeeVoice,
  VoiceoverSettings,
  voiceoverService,
} from "../../services/voiceoverService";

/**
 * Picks the ONE Vietnamese narrator every Vbee-dubbed course uses.
 *
 * This does not reopen the per-run voice picker that was deliberately removed
 * from this feature — the narrator is still fixed per language. It exists
 * because Vbee's narrator is a PRICING decision as much as a casting one
 * (`creditFactor` 1, 2 or 3 characters billed per character read), and pricing
 * should not need a deploy. The factor is shown on every row for that reason.
 */

const GENDER_LABEL: Record<string, string> = {
  female: "Nữ",
  male: "Nam",
};

/** Highlights the tiers that cost more, so a 3x voice is never picked by accident. */
const FACTOR_CLASS = (factor: number): string =>
  factor >= 3
    ? "bg-red-100 text-red-700"
    : factor === 2
    ? "bg-amber-100 text-amber-700"
    : "bg-green-100 text-green-700";

interface Props {
  settings: VoiceoverSettings | null;
  onSaved: (settings: VoiceoverSettings) => void;
  onError: (message: string) => void;
  onSuccess: (message: string) => void;
}

export default function VbeeVoicePanel({
  settings,
  onSaved,
  onError,
  onSuccess,
}: Props) {
  const [voices, setVoices] = useState<VbeeVoice[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selected, setSelected] = useState<string>("");
  const [saving, setSaving] = useState(false);
  const [playing, setPlaying] = useState<string | null>(null);
  const [pasted, setPasted] = useState("");
  // Kept from the last save: a code the API could not place in any catalogue is
  // accepted, not refused, so the caution has to persist to be read.
  const [warning, setWarning] = useState<string | null>(null);

  // One element for the whole list: two demos playing at once is never wanted,
  // and reusing it means switching rows stops the previous clip for free.
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const configured = Boolean(settings?.vbeeConfigured);

  useEffect(() => {
    setSelected(settings?.vbeeVoiceCode ?? "");
  }, [settings?.vbeeVoiceCode]);

  useEffect(() => {
    if (!configured) return;
    let cancelled = false;

    setLoading(true);
    voiceoverService
      .getVbeeVoices()
      .then((list) => {
        if (cancelled) return;
        setVoices(list);
        setLoadError(null);
      })
      .catch((err: any) => {
        if (cancelled) return;
        setLoadError(
          err?.response?.data?.message ||
            err?.message ||
            "Không đọc được danh sách giọng Vbee"
        );
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [configured]);

  // Stop any demo when the panel goes away, so audio never outlives the page.
  useEffect(
    () => () => {
      audioRef.current?.pause();
      audioRef.current = null;
    },
    []
  );

  const current = useMemo(
    () => voices.find((voice) => voice.code === selected),
    [voices, selected]
  );

  const dirty = Boolean(selected) && selected !== settings?.vbeeVoiceCode;

  const togglePreview = (voice: VbeeVoice) => {
    if (!voice.demo) return;

    if (playing === voice.code) {
      audioRef.current?.pause();
      setPlaying(null);
      return;
    }

    audioRef.current?.pause();
    const audio = new Audio(voice.demo);
    audio.onended = () => setPlaying(null);
    audio.onerror = () => {
      setPlaying(null);
      onError(`Không phát được giọng thử "${voice.name}"`);
    };
    audioRef.current = audio;
    void audio.play();
    setPlaying(voice.code);
  };

  const saveCode = async (code: string, label: string) => {
    if (saving || !code.trim()) return;
    setSaving(true);
    try {
      const saved = await voiceoverService.updateVbeeVoice(code.trim());
      onSaved(saved);
      setWarning(saved.warning ?? null);
      setSelected(saved.vbeeVoiceCode);
      setPasted("");
      onSuccess(`Đã đổi giọng Vbee sang "${label}"`);
    } catch (err: any) {
      onError(err?.response?.data?.message || "Không lưu được giọng Vbee");
    } finally {
      setSaving(false);
    }
  };

  const handleSave = () => {
    if (!dirty) return;
    return saveCode(selected, current?.name ?? selected);
  };

  if (!configured) {
    return (
      <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
        <p className="font-medium">Vbee chưa được cấu hình trên môi trường này.</p>
        <p className="mt-0.5 text-xs">
          Đặt <code className="font-mono">VBEE_APP_ID</code> và{" "}
          <code className="font-mono">VBEE_TOKEN</code> trong <code className="font-mono">.env</code> của
          API rồi deploy lại. Cho tới lúc đó mọi khoá học vẫn dub bằng giọng Edge miễn phí.
        </p>
      </div>
    );
  }

  return (
    <section className="rounded-lg border border-slate-200 bg-white">
      <header className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 px-4 py-3">
        <div>
          <h2 className="text-sm font-semibold text-slate-900">Giọng Vbee (tiếng Việt)</h2>
          <p className="mt-0.5 text-xs text-slate-500">
            Dùng cho mọi khoá học đã bật Vbee. Bốn ngôn ngữ còn lại luôn dùng giọng Edge miễn phí.
          </p>
        </div>
        <button
          type="button"
          onClick={handleSave}
          disabled={!dirty || saving}
          className="inline-flex items-center gap-1.5 rounded-md bg-bronze-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-bronze-700 disabled:opacity-50"
        >
          {saving ? (
            <Loader2Icon className="h-3.5 w-3.5 animate-spin" />
          ) : (
            <SaveIcon className="h-3.5 w-3.5" />
          )}
          Lưu giọng
        </button>
      </header>

      {/* Paste box. The list above is Vbee's own catalogue only; a community
          voice or the account's own cloned one has a perfectly valid code that
          will never appear there, and pasting is the only way to reach it. */}
      <div className="space-y-2 border-b border-slate-100 bg-slate-50/60 px-4 py-3">
        <div className="flex flex-wrap items-center gap-2">
          <input
            type="text"
            value={pasted}
            onChange={(event) => setPasted(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter" && pasted.trim()) {
                void saveCode(pasted, pasted.trim());
              }
            }}
            placeholder="Dán mã giọng, ví dụ hn_female_ngochuyen_full_48k-fhg"
            className="min-w-0 flex-1 rounded-md border border-slate-300 bg-white px-2.5 py-1.5 font-mono text-xs text-slate-800 placeholder:font-sans placeholder:text-slate-400 focus:border-bronze-400 focus:outline-none"
          />
          <button
            type="button"
            onClick={() => saveCode(pasted, pasted.trim())}
            disabled={!pasted.trim() || saving}
            className="shrink-0 rounded-md border border-slate-300 bg-white px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
          >
            Dùng mã này
          </button>
        </div>
        <p className="text-[11px] text-slate-500">
          Đang dùng:{" "}
          <span className="font-mono text-slate-700">
            {settings?.vbeeVoiceCode || "—"}
          </span>
          {current ? ` · ${current.name} · ×${current.creditFactor}` : ""}
        </p>
        {warning && (
          <p className="rounded-md bg-amber-50 px-3 py-2 text-[11px] text-amber-800">
            {warning}
          </p>
        )}
      </div>

      {loading ? (
        <p className="flex items-center gap-2 px-4 py-6 text-sm text-slate-500">
          <Loader2Icon className="h-4 w-4 animate-spin" /> Đang tải danh sách giọng…
        </p>
      ) : loadError ? (
        <p className="px-4 py-6 text-sm text-red-600">{loadError}</p>
      ) : (
        <div className="max-h-72 overflow-y-auto">
          <ul className="divide-y divide-slate-100">
            {voices.map((voice) => {
              const isSelected = voice.code === selected;
              return (
                <li
                  key={voice.code}
                  className={`flex items-center gap-3 px-4 py-2 ${
                    isSelected ? "bg-bronze-50/60" : "hover:bg-slate-50"
                  }`}
                >
                  <input
                    type="radio"
                    name="vbee-voice"
                    checked={isSelected}
                    onChange={() => setSelected(voice.code)}
                    className="h-4 w-4 accent-bronze-600"
                    aria-label={`Chọn giọng ${voice.name}`}
                  />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-slate-900">
                      {voice.name}
                      <span className="ml-2 text-xs font-normal text-slate-400">
                        {GENDER_LABEL[voice.gender] ?? voice.gender}
                      </span>
                    </p>
                    <p className="truncate font-mono text-[11px] text-slate-400">
                      {voice.code}
                    </p>
                  </div>
                  <span
                    className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold ${FACTOR_CLASS(
                      voice.creditFactor
                    )}`}
                    title="Số điểm bị trừ cho mỗi ký tự đọc"
                  >
                    ×{voice.creditFactor}
                  </span>
                  <button
                    type="button"
                    onClick={() => togglePreview(voice)}
                    disabled={!voice.demo}
                    title={voice.demo ? "Nghe thử" : "Giọng này không có bản nghe thử"}
                    className="shrink-0 rounded-md border border-slate-300 bg-white p-1.5 text-slate-600 hover:bg-slate-50 disabled:opacity-40"
                  >
                    {playing === voice.code ? (
                      <PauseIcon className="h-3.5 w-3.5" />
                    ) : (
                      <PlayIcon className="h-3.5 w-3.5" />
                    )}
                  </button>
                </li>
              );
            })}
            {!voices.length && (
              <li className="px-4 py-6 text-sm text-slate-400">
                Tài khoản Vbee này chưa có giọng tiếng Việt nào.
              </li>
            )}
          </ul>
        </div>
      )}
    </section>
  );
}
