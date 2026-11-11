import { TrashIcon } from "@heroicons/react/24/outline";
import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyClosedQuestionType,
  InAppSurveyBranchPayload,
  InAppSurveyOptionPayload,
} from "../../../types/interface/in-app-survey.interface";
import CloudflareFileUpload from "../../files/CloudflareFileUpload";
import InAppSurveyOptionFields from "./InAppSurveyOptionFields";
import InAppSurveyQuestionFields from "./InAppSurveyQuestionFields";
import { emptySurveyOption } from "./in-app-survey-form-utils";

interface Props {
  branch: InAppSurveyBranchPayload;
  branchIndex: number;
  lang: LangCode;
  onChange: (branchIndex: number, nextBranch: InAppSurveyBranchPayload) => void;
  onRemove: (branchIndex: number) => void;
}

const SortableInAppSurveyBranchCard = ({
  branch,
  branchIndex,
  lang,
  onChange,
  onRemove,
}: Props) => {
  const updateOptions = (
    optionIndex: number,
    nextOption: Partial<InAppSurveyOptionPayload>,
  ) => {
    onChange(branchIndex, {
      ...branch,
      closedQuestion: {
        ...branch.closedQuestion,
        options: branch.closedQuestion.options.map((option, index) =>
          index === optionIndex ? { ...option, ...nextOption } : option,
        ),
      },
    });
  };

  const reorderOptions = (oldIndex: number, newIndex: number) => {
    const nextOptions = [...branch.closedQuestion.options];
    const [movedOption] = nextOptions.splice(oldIndex, 1);
    nextOptions.splice(newIndex, 0, movedOption);

    onChange(branchIndex, {
      ...branch,
      closedQuestion: {
        ...branch.closedQuestion,
        options: nextOptions,
      },
    });
  };

  return (
    <div className="rounded-2xl border border-bronze-100 bg-gradient-to-br from-white to-slate-50 p-5 shadow-sm">
      <div className="mb-4 flex items-center justify-between gap-3 border-b border-bronze-100 pb-4">
        <div className="flex items-center gap-3">
          <div>
            <div className="text-xs font-semibold uppercase tracking-wide text-bronze-600">
              Branch #{branchIndex + 1}
            </div>
            <div className="text-lg font-semibold text-slate-950">
              {branch.emoji.name || "Unnamed emoji branch"}
            </div>
            {branch.id ? (
              <div className="mt-1 flex items-center gap-1 text-xs text-slate-500">
                <span className="font-medium">branch_key:</span>
                <code className="select-all rounded bg-slate-100 px-1.5 py-0.5 font-mono text-[11px] text-slate-700">
                  {branch.id}
                </code>
              </div>
            ) : null}
          </div>
        </div>
        <button
          type="button"
          onClick={() => onRemove(branchIndex)}
          className="rounded-xl bg-red-50 p-2 text-red-600 transition hover:bg-red-100"
        >
          <TrashIcon className="h-5 w-5" />
        </button>
      </div>

      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(320px,0.8fr)_minmax(460px,1.2fr)]">
        <div className="space-y-4">
          <div className="rounded-2xl border border-bronze-100 bg-bronze-50/30 p-4">
            <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-[160px_160px_1fr]">
              <CloudflareFileUpload
                initialUrl={branch.emoji.darkUrl}
                onUrlChange={(darkUrl) =>
                  onChange(branchIndex, {
                    ...branch,
                    emoji: { ...branch.emoji, darkUrl },
                  })
                }
                label="Dark Emoji"
                uploadPayload={{ prefix: "", folder: "in-app-survey" }}
              />
              <CloudflareFileUpload
                initialUrl={branch.emoji.lightUrl || ""}
                onUrlChange={(lightUrl) =>
                  onChange(branchIndex, {
                    ...branch,
                    emoji: { ...branch.emoji, lightUrl },
                  })
                }
                label="Light Emoji"
                uploadPayload={{ prefix: "", folder: "in-app-survey" }}
              />
              <div className="min-w-0">
                <label className="mb-1 block text-sm font-semibold text-bronze-900">
                  Emoji Name
                </label>
                <input
                  value={branch.emoji.name || ""}
                  onChange={(e) =>
                    onChange(branchIndex, {
                      ...branch,
                      emoji: { ...branch.emoji, name: e.target.value },
                    })
                  }
                  className="w-full rounded-xl border border-bronze-200 bg-white px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-bronze-400 focus:ring-2 focus:ring-bronze-100"
                />
              </div>
            </div>
          </div>

          <InAppSurveyQuestionFields
            title="Open Question"
            questionNumber="Q3"
            lang={lang}
            value={branch.openQuestion}
            onChange={(nextValue) =>
              onChange(branchIndex, {
                ...branch,
                openQuestion: nextValue,
              })
            }
          />
        </div>

        <div className="space-y-4">
          <InAppSurveyQuestionFields
            title="Closed Question"
            questionNumber="Q2"
            lang={lang}
            value={branch.closedQuestion}
            onChange={(nextValue) =>
              onChange(branchIndex, {
                ...branch,
                closedQuestion: {
                  ...branch.closedQuestion,
                  ...nextValue,
                },
              })
            }
          />
          <InAppSurveyOptionFields
            lang={lang}
            options={branch.closedQuestion.options}
            selectionType={
              branch.closedQuestion.type ||
              InAppSurveyClosedQuestionType.MULTIPLE_CHOICE
            }
            onAdd={() =>
              onChange(branchIndex, {
                ...branch,
                closedQuestion: {
                  ...branch.closedQuestion,
                  options: [
                    ...branch.closedQuestion.options,
                    emptySurveyOption(lang),
                  ],
                },
              })
            }
            onChange={updateOptions}
            onReorder={reorderOptions}
            onSelectionTypeChange={(type) =>
              onChange(branchIndex, {
                ...branch,
                closedQuestion: {
                  ...branch.closedQuestion,
                  type,
                },
              })
            }
            onRemove={(optionIndex) =>
              onChange(branchIndex, {
                ...branch,
                closedQuestion: {
                  ...branch.closedQuestion,
                  options:
                    branch.closedQuestion.options.length > 1
                      ? branch.closedQuestion.options.filter(
                          (_, index) => index !== optionIndex,
                        )
                      : branch.closedQuestion.options,
                },
              })
            }
          />
        </div>
      </div>
    </div>
  );
};

export default SortableInAppSurveyBranchCard;
