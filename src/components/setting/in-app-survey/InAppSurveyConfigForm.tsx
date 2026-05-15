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

const InAppSurveyConfigForm = ({
  lang,
  formData,
  onSubmit,
  setFormData,
}: Props) => {
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
    <form onSubmit={onSubmit} className="space-y-6">
      <InAppSurveyQuestionFields
        title="Intro Question"
        tone="intro"
        compactQuestion
        questionNumber="Q1"
        lang={lang}
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
              lang={lang}
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
                branches: [...prev.branches, emptySurveyBranch(lang)],
              }))
            }
            className="inline-flex items-center gap-2 rounded-full bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-700"
          >
            <PlusIcon className="h-4 w-4" />
            Add Branch
          </button>
        </div>
      </div>

      <div className="sticky bottom-0 flex justify-end border-t border-slate-200 bg-white/95 py-4 backdrop-blur">
        <button
          type="submit"
          className="rounded-xl bg-sky-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-sky-700"
        >
          Save Survey Config
        </button>
      </div>
    </form>
  );
};

export default InAppSurveyConfigForm;
