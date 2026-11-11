import { useState } from "react";
import { PlusIcon } from "@heroicons/react/24/outline";
import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyBranchPayload,
  InAppSurveyConfigPayload,
} from "../../../types/interface/in-app-survey.interface";
import InAppSurveyQuestionFields from "./InAppSurveyQuestionFields";
import SortableInAppSurveyBranchCard from "./SortableInAppSurveyBranchCard";
import { emptySurveyBranch } from "./in-app-survey-form-utils";

interface Props {
  lang: LangCode;
  formData: InAppSurveyConfigPayload;
  onSubmit: (event: React.FormEvent) => void;
  setFormData: React.Dispatch<React.SetStateAction<InAppSurveyConfigPayload>>;
}

const LANG_OPTIONS: { code: LangCode; label: string }[] = [
  { code: LangCode.VI, label: "Tiếng Việt" },
  { code: LangCode.EN, label: "Tiếng Anh" },
  { code: LangCode.ZH, label: "Tiếng Trung" },
  { code: LangCode.JA, label: "Tiếng Nhật" },
  { code: LangCode.KO, label: "Tiếng Hàn" },
];

const InAppSurveyConfigForm = ({
  lang,
  formData,
  onSubmit,
  setFormData,
}: Props) => {
  const [editLang, setEditLang] = useState<LangCode>(lang);

  const updateBranch = (
    branchIndex: number,
    nextBranch: InAppSurveyBranchPayload,
  ) => {
    setFormData((prev) => ({
      ...prev,
      branches: prev.branches.map((branch, index) =>
        index === branchIndex ? nextBranch : branch,
      ),
    }));
  };

  return (
    <form
      id="in-app-survey-config-form"
      onSubmit={onSubmit}
      className="space-y-6"
    >
      <div className="flex flex-wrap items-center gap-2 rounded-2xl border border-slate-200 bg-white p-3 shadow-sm">
        <span className="mr-1 text-xs font-semibold uppercase tracking-wide text-slate-500">
          Ngôn ngữ đang sửa
        </span>
        {LANG_OPTIONS.map((option) => (
          <button
            key={option.code}
            type="button"
            onClick={() => setEditLang(option.code)}
            className={`rounded-lg px-3 py-1.5 text-sm font-semibold transition ${
              editLang === option.code
                ? "bg-bronze-600 text-white shadow-sm"
                : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            {option.label}
          </button>
        ))}
      </div>

      <InAppSurveyQuestionFields
        title="Intro Question"
        tone="intro"
        compactQuestion
        questionNumber="Q1"
        lang={editLang}
        value={formData.introQuestion}
        onChange={(introQuestion) =>
          setFormData((prev) => ({ ...prev, introQuestion }))
        }
      />

      <div className="space-y-4">
        <div className="space-y-4">
          {formData.branches.map((branch, branchIndex) => (
            <SortableInAppSurveyBranchCard
              key={branch.id || branchIndex}
              branch={branch}
              branchIndex={branchIndex}
              lang={editLang}
              onChange={updateBranch}
              onRemove={(index) =>
                setFormData((prev) => ({
                  ...prev,
                  branches:
                    prev.branches.length > 1
                      ? prev.branches.filter((_, i) => i !== index)
                      : prev.branches,
                }))
              }
            />
          ))}
        </div>
        <div className="flex justify-center pt-2">
          <button
            type="button"
            onClick={() =>
              setFormData((prev) => ({
                ...prev,
                branches: [...prev.branches, emptySurveyBranch(editLang)],
              }))
            }
            className="inline-flex items-center gap-2 rounded-full bg-bronze-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-bronze-700"
          >
            <PlusIcon className="h-4 w-4" />
            Add Branch
          </button>
        </div>
      </div>
    </form>
  );
};

export default InAppSurveyConfigForm;
