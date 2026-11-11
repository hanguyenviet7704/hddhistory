import { ReactNode } from "react";
import { LangCode } from "../../../types/enum/common.enum";
import { IInAppSurveyResponse } from "../../../types/interface/in-app-survey.interface";
import InAppSurveyEmojiImage from "./InAppSurveyEmojiImage";
import {
  formatDateTime,
  getBranchLabel,
  getPlainTranslationValue,
  getQuestionText,
} from "./in-app-survey-analytics-utils";

interface Props {
  response: IInAppSurveyResponse;
  lang: LangCode;
}

const InAppSurveyUserResponseCard = ({ response, lang }: Props) => {
  const userName =
    response.userSnapshot?.name || response.userSnapshot?.email || null;
  const initials = userName ? userName.slice(0, 2).toUpperCase() : "--";

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-100 pb-4">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-bronze-50 text-sm font-bold text-bronze-600">
            {initials}
          </div>
          <div>
            <div className="font-bold text-slate-950">
              {userName || "No user snapshot"}
            </div>
            <div className="text-sm text-slate-400">
              {formatDateTime(response.submittedAt || response.createdAt)}
            </div>
          </div>
        </div>
        <div className="inline-flex items-center gap-2 rounded-full bg-stone-100 px-3 py-1 text-sm font-semibold text-slate-700">
          <InAppSurveyEmojiImage
            emoji={response.branch?.emoji}
            label={response.branchName}
            score={response.ratingScore}
            className="h-5 w-5"
          />
          {getBranchLabel(response.ratingScore, response.branchName)}
        </div>
      </div>
      <div className="mt-4 space-y-4">
        <QuestionRow
          label="Q2"
          title={getQuestionText(response.branch?.closedQuestion, lang)}
        >
          {response.selectedOptions.map((option) => (
            <div
              key={option.id}
              className="rounded-xl bg-slate-50 px-4 py-3 text-sm text-slate-900"
            >
              {getPlainTranslationValue(option.value, lang)}
            </div>
          ))}
        </QuestionRow>
        <QuestionRow
          label="Q3"
          title={getQuestionText(response.branch?.openQuestion, lang)}
        >
          <div className="rounded-xl border-l-4 border-bronze-200 bg-slate-50 px-4 py-3 text-sm leading-6 text-slate-950">
            "{response.feedback || "-"}"
          </div>
        </QuestionRow>
      </div>
    </div>
  );
};

const QuestionRow = ({
  label,
  title,
  children,
}: {
  label: string;
  title: string;
  children: ReactNode;
}) => (
  <div>
    <div className="mb-2 flex items-center gap-2">
      <span className="rounded-md bg-bronze-50 px-2 py-1 text-xs font-bold text-bronze-600">
        {label}
      </span>
      <span className="text-sm font-semibold text-slate-500">{title}</span>
    </div>
    <div className="space-y-2">{children}</div>
  </div>
);

export default InAppSurveyUserResponseCard;
