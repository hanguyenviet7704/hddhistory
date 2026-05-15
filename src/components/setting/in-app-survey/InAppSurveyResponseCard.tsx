import { ReactNode } from "react";
import { Tooltip } from "@mui/material";
import { LangCode } from "../../../types/enum/common.enum";
import { IInAppSurveyResponse } from "../../../types/interface/in-app-survey.interface";
import { getTranslationValue } from "../../../utils/translation";

interface Props {
  response: IInAppSurveyResponse;
  lang: LangCode;
}

const formatDate = (value?: string) => {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("vi-VN", { hour12: false });
};

const TextTooltip = ({
  children,
  text,
  className = "",
}: {
  children: ReactNode;
  text: string;
  className?: string;
}) => (
  <Tooltip title={<span className="whitespace-pre-wrap">{text}</span>} arrow>
    <div className={className}>{children}</div>
  </Tooltip>
);

const InAppSurveyResponseCard = ({ response, lang }: Props) => {
  const emoji = response.branch?.emoji;
  const optionTexts = response.selectedOptions
    ?.map((option) => getTranslationValue(option.value, lang))
    .filter(Boolean);
  const question =
    getTranslationValue(response.branch?.openQuestion?.question, lang) || "-";
  const feedback = response.feedback || "-";

  return (
    <div className="space-y-3 p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-3">
          {emoji?.url ? (
            <img
              src={emoji.url}
              alt={emoji.name || "Selected emoji"}
              className="h-9 w-9 rounded-full border border-slate-200 object-cover"
            />
          ) : (
            <div className="h-9 w-9 rounded-full border border-slate-200 bg-slate-100" />
          )}
          <div>
            <div className="text-sm font-semibold text-slate-900">
              {emoji?.name || "Selected emoji"}
            </div>
          </div>
        </div>
        <div className="text-xs text-slate-500">
          {formatDate(response.submittedAt || response.createdAt)}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-3 text-sm md:grid-cols-3">
        <div>
          <div className="text-xs font-semibold uppercase text-slate-400">
            Selected Options
          </div>
          <div className="mt-1 space-y-1 text-slate-900">
            {optionTexts?.length ? (
              optionTexts.map((text, index) => (
                <TextTooltip
                  key={`${text}-${index}`}
                  text={text}
                  className="cursor-help truncate"
                >
                  {text}
                </TextTooltip>
              ))
            ) : (
              <span>-</span>
            )}
          </div>
        </div>
        <div>
          <div className="text-xs font-semibold uppercase text-slate-400">
            Question
          </div>
          <TextTooltip text={question} className="mt-1 cursor-help truncate">
            {question}
          </TextTooltip>
        </div>
        <div>
          <div className="text-xs font-semibold uppercase text-slate-400">
            Feedback
          </div>
          <TextTooltip
            text={feedback}
            className="mt-1 cursor-help overflow-hidden whitespace-pre-wrap text-slate-900"
          >
            <div
              style={{
                display: "-webkit-box",
                WebkitLineClamp: 2,
                WebkitBoxOrient: "vertical",
                overflow: "hidden",
              }}
            >
              {feedback}
            </div>
          </TextTooltip>
        </div>
      </div>
    </div>
  );
};

export default InAppSurveyResponseCard;
