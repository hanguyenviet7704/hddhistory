import { useEffect, useState } from "react";

import {
  voiceoverService,
  VoiceoverVoiceOption,
  VoiceoverVoiceSelection,
} from "../../services/voiceoverService";

const LANG_LABELS: Record<string, string> = {
  vi: "VI",
  en: "EN",
  zh: "ZH",
  ja: "JA",
  ko: "KO",
};

interface VoiceoverVoicePickerProps {
  value: VoiceoverVoiceSelection;
  onChange: (next: VoiceoverVoiceSelection) => void;
  disabled?: boolean;
}

/// One narrator select PER LANGUAGE, populated from the TTS endpoint's own
/// catalogue.
///
/// Two deliberate choices here:
///
/// - **Per language, not one narrator for the run.** Dub failures are per
///   language — Chinese was erroring on its own — and a single global narrator
///   cannot express "leave the other four alone".
/// - **Options are fetched, never hardcoded.** A voice name invented on the
///   client is exactly how every Chinese keypoint ended up failing with
///   `Voice 'zh-CN-Chirp3-HD-Zephyr' does not exist` (a Google-era name built by
///   concatenation).
///
/// An empty value means "keep whatever that language was last dubbed with",
/// which is why the placeholder option is not a real voice.
export default function VoiceoverVoicePicker({
  value,
  onChange,
  disabled,
}: VoiceoverVoicePickerProps) {
  const [options, setOptions] = useState<Record<string, VoiceoverVoiceOption[]>>(
    {}
  );
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const data = await voiceoverService.getVoiceOptions();
        // Keep only languages that really came back as a list. This picker is an
        // optional enhancement on a page whose actual job is the coverage report,
        // so a payload in an unexpected shape has to degrade to the notice below
        // — an early version let one bad shape throw and white-screened the whole
        // page.
        const lists = Object.fromEntries(
          Object.entries(data ?? {}).filter(([, value]) => Array.isArray(value))
        ) as Record<string, VoiceoverVoiceOption[]>;
        if (alive) setOptions(lists);
      } catch (err: any) {
        if (alive) {
          setError(
            err?.response?.data?.message ??
              err?.message ??
              "Không tải được danh sách giọng"
          );
        }
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  if (loading) {
    return (
      <span className="text-sm text-slate-500">Đang tải danh sách giọng…</span>
    );
  }

  // The picker is an enhancement, not a gate: generation still works without it
  // (each language falls back to its own default), so a failed list is a notice
  // rather than a blocker.
  if (error) {
    return (
      <span
        className="text-sm text-amber-700"
        title="Sinh voiceover vẫn chạy được — mỗi ngôn ngữ sẽ dùng giọng mặc định."
      >
        Không tải được giọng ({error}) — sẽ dùng giọng mặc định
      </span>
    );
  }

  const langs = Object.keys(options);
  if (!langs.length) {
    return (
      <span className="text-sm text-slate-500">
        Không lấy được danh sách giọng
      </span>
    );
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      <span className="text-sm text-slate-500">Giọng</span>
      {langs.map((lang) => {
        const langOptions = options[lang] ?? [];
        return (
          <label key={lang} className="flex items-center gap-1 text-sm">
            <span className="font-medium text-slate-500">
              {LANG_LABELS[lang] ?? lang.toUpperCase()}
            </span>
            <select
              value={value[lang] ?? ""}
              onChange={(e) => {
                const next = { ...value };
                if (e.target.value) next[lang] = e.target.value;
                else delete next[lang];
                onChange(next);
              }}
              disabled={disabled || !langOptions.length}
              className="rounded-lg border border-slate-300 bg-white px-2 py-2 text-sm font-medium text-slate-700 shadow-sm disabled:opacity-60"
              aria-label={`Giọng đọc ${LANG_LABELS[lang] ?? lang}`}
            >
              <option value="">
                {langOptions.length ? "Mặc định" : "Không có giọng"}
              </option>
              {langOptions.map((option) => (
                <option key={option.name} value={option.name}>
                  {option.speaker}
                  {option.gender === "FEMALE"
                    ? " (nữ)"
                    : option.gender === "MALE"
                      ? " (nam)"
                      : ""}
                </option>
              ))}
            </select>
          </label>
        );
      })}
    </div>
  );
}
