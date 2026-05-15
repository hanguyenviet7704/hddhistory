import { LangCode } from "../../../types/enum/common.enum";
import { IInAppSurveyQuestion } from "../../../types/interface/in-app-survey.interface";
import { updateTranslationValue } from "../../../utils/translation";

interface Props {
  title: string;
  lang: LangCode;
  value: IInAppSurveyQuestion;
  onChange: (nextValue: IInAppSurveyQuestion) => void;
  compactQuestion?: boolean;
  questionNumber?: "Q1" | "Q2" | "Q3";
  tone?: "default" | "intro";
}

const InAppSurveyQuestionFields = ({
  title,
  lang,
  value,
  onChange,
  compactQuestion = false,
  questionNumber,
  tone = "default",
}: Props) => (
  <div
    className={`space-y-4 rounded-2xl border p-4 shadow-sm ${
      tone === "intro"
        ? "border-sky-100 bg-gradient-to-br from-sky-50 via-white to-indigo-50"
        : "border-slate-200 bg-white"
    }`}
  >
    <div className="flex items-center gap-2">
      {questionNumber ? (
        <span
          className={`rounded-full px-2.5 py-1 text-xs font-bold ${
            tone === "intro"
              ? "bg-sky-600 text-white"
              : "bg-indigo-100 text-indigo-700"
          }`}
        >
          {questionNumber}
        </span>
      ) : null}
      <p
        className={`text-xs font-semibold uppercase tracking-wide ${
          tone === "intro" ? "text-sky-700" : "text-slate-500"
        }`}
      >
        {title}
      </p>
    </div>
    <div>
      <label
        className={`mb-1 block text-sm font-semibold ${
          tone === "intro" ? "text-sky-800" : "text-slate-700"
        }`}
      >
        Question ({lang})
      </label>
      {compactQuestion ? (
        <input
          value={value.question?.[lang] || ""}
          onChange={(e) =>
            onChange({
              ...value,
              question: updateTranslationValue(
                value.question,
                lang,
                e.target.value,
              ),
            })
          }
          className="w-full rounded-xl border border-sky-200 bg-white px-4 py-3 text-sm font-medium text-slate-950 shadow-sm outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
          placeholder="Enter the intro question"
          required
        />
      ) : (
        <textarea
          rows={2}
          value={value.question?.[lang] || ""}
          onChange={(e) =>
            onChange({
              ...value,
              question: updateTranslationValue(
                value.question,
                lang,
                e.target.value,
              ),
            })
          }
          className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 outline-none transition focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100"
          required
        />
      )}
    </div>
    <div>
      <label className="mb-1 block text-sm font-semibold text-slate-700">
        Guide ({lang})
      </label>
      <textarea
        rows={2}
        value={value.guide?.[lang] || ""}
        onChange={(e) =>
          onChange({
            ...value,
            guide: updateTranslationValue(value.guide, lang, e.target.value),
          })
        }
        className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 outline-none transition focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100"
        placeholder="Optional guide text"
      />
    </div>
  </div>
);

export default InAppSurveyQuestionFields;
