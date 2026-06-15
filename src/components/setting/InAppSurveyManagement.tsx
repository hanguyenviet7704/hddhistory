import { useCallback, useEffect, useState } from "react";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { LangCode } from "../../types/enum/common.enum";
import { InAppSurveyConfigPayload } from "../../types/interface/in-app-survey.interface";
import { inAppSurveyService } from "../../services/inAppSurveyService";
import { useNotification } from "../../utils/hooks/useNotification";
import ExcelImportButton from "../imports/ExcelImportButton";
import InAppSurveyConfigForm from "./in-app-survey/InAppSurveyConfigForm";
import InAppSurveyFeedbackList from "./in-app-survey/InAppSurveyFeedbackList";
import {
  buildSurveyPayload,
  emptySurveyPayload,
  normalizeSurveyConfig,
} from "./in-app-survey/in-app-survey-form-utils";

type SurveyTab = "editor" | "feedback";

const InAppSurveyManagement = () => {
  const lang = useSelector((state: RootState) => state.lang.code) as LangCode;
  const { showSuccess, showError } = useNotification();

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<SurveyTab>("editor");
  const [formData, setFormData] = useState<InAppSurveyConfigPayload>(
    emptySurveyPayload(lang),
  );

  const fetchConfig = useCallback(async () => {
    try {
      setLoading(true);
      const res = await inAppSurveyService.getConfig();
      setFormData(normalizeSurveyConfig(res, lang));
    } catch (err: any) {
      if (err?.response?.status === 404) {
        setFormData(emptySurveyPayload(lang));
        return;
      }
      console.error("Failed to fetch in-app survey config", err);
      showError("Tải cấu hình survey thất bại");
    } finally {
      setLoading(false);
    }
  }, [lang, showError]);

  useEffect(() => {
    if (activeTab === "editor") {
      fetchConfig();
    }
  }, [activeTab, fetchConfig]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    try {
      setSaving(true);
      const saved = await inAppSurveyService.saveConfig(
        buildSurveyPayload(formData, lang),
      );
      setFormData(normalizeSurveyConfig(saved, lang));
      showSuccess("Lưu cấu hình survey thành công");
    } catch (err) {
      console.error("Failed to save in-app survey config", err);
      showError("Lưu cấu hình survey thất bại");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="sticky top-0 z-20 flex flex-wrap items-center justify-between gap-3 border-b border-slate-200 bg-white/95 py-3 backdrop-blur">
        <div className="flex w-fit rounded-xl border border-slate-200 bg-white p-1 shadow-sm">
          {[
            { key: "editor" as const, label: "Editor" },
            { key: "feedback" as const, label: "Feedback" },
          ].map((tab) => (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveTab(tab.key)}
              className={`rounded-lg px-4 py-2 text-sm font-semibold transition ${
                activeTab === tab.key
                  ? "bg-indigo-600 text-white shadow-sm"
                  : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {activeTab === "editor" ? (
          <div className="flex flex-wrap items-center gap-3">
            <button
              type="button"
              onClick={async () => {
                try {
                  const res =
                    await inAppSurveyService.downloadImportTemplate();
                  const url = URL.createObjectURL(res.data);
                  const a = document.createElement("a");
                  a.href = url;
                  a.download = "in-app-survey-import-template.xlsx";
                  a.click();
                  URL.revokeObjectURL(url);
                } catch {
                  showError("Tải template thất bại");
                }
              }}
              className="inline-flex items-center gap-2 rounded-lg border border-slate-400 px-3 py-2 text-sm text-slate-600 transition hover:bg-slate-50"
            >
              Template
            </button>

            <ExcelImportButton
              label="Import"
              fileName="in-app-survey-import-result.xlsx"
              importExcel={inAppSurveyService.importExcel}
              onSuccess={() => {
                showSuccess("Import survey thành công");
                fetchConfig();
              }}
              onError={showError}
            />

            <button
              type="submit"
              form="in-app-survey-config-form"
              disabled={saving || loading}
              className="rounded-xl bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-emerald-700 disabled:cursor-not-allowed disabled:bg-emerald-300"
            >
              Save Survey
            </button>
          </div>
        ) : null}
      </div>

      {activeTab === "editor" ? (
        loading ? (
          <div className="rounded-xl border border-gray-200 bg-white p-8 text-center text-gray-500">
            Loading survey config...
          </div>
        ) : (
          <InAppSurveyConfigForm
            lang={lang}
            formData={formData}
            onSubmit={handleSubmit}
            setFormData={setFormData}
          />
        )
      ) : (
        <InAppSurveyFeedbackList lang={lang} />
      )}

      {saving && activeTab === "editor" ? (
        <div className="fixed bottom-4 right-4 rounded-lg bg-sky-600 px-4 py-2 text-sm text-white shadow-lg">
          Saving survey config...
        </div>
      ) : null}
    </div>
  );
};

export default InAppSurveyManagement;
