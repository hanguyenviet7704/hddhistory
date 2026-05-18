import { LangCode } from "../../../types/enum/common.enum";
import {
  IInAppSurveyConfig,
  InAppSurveyClosedQuestionType,
  InAppSurveyBranchPayload,
  InAppSurveyConfigPayload,
  InAppSurveyOptionPayload,
} from "../../../types/interface/in-app-survey.interface";
import { cleanTranslation } from "../../../utils/translation";

export const emptySurveyQuestion = (lang: LangCode) => ({
  question: { [lang]: "" },
  guide: { [lang]: "" },
});

export const emptySurveyOption = (
  lang: LangCode
): InAppSurveyOptionPayload => ({
  icon: "",
  value: { [lang]: "" },
});

export const emptySurveyBranch = (
  lang: LangCode
): InAppSurveyBranchPayload => ({
  emoji: { name: "", darkUrl: "", lightUrl: "" },
  closedQuestion: {
    ...emptySurveyQuestion(lang),
    type: InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
    options: [emptySurveyOption(lang)],
  },
  openQuestion: emptySurveyQuestion(lang),
});

export const emptySurveyPayload = (lang: LangCode): InAppSurveyConfigPayload => ({
  introQuestion: emptySurveyQuestion(lang),
  branches: [emptySurveyBranch(lang)],
});

export const normalizeSurveyConfig = (
  payload: any,
  lang: LangCode
): InAppSurveyConfigPayload => {
  const data: IInAppSurveyConfig | null = payload?.data ?? payload ?? null;
  if (!data?.introQuestion || !Array.isArray(data.branches)) {
    return emptySurveyPayload(lang);
  }

  return {
    introQuestion: data.introQuestion,
    branches: data.branches.length
      ? data.branches.map((branch: any) => ({
          ...branch,
          emoji: {
            name: branch.emoji?.name || "",
            darkUrl: branch.emoji?.darkUrl || branch.emoji?.url || "",
            lightUrl: branch.emoji?.lightUrl || "",
          },
        }))
      : [emptySurveyBranch(lang)],
  };
};

export const buildSurveyPayload = (
  formData: InAppSurveyConfigPayload,
  lang: LangCode
): InAppSurveyConfigPayload => ({
  introQuestion: {
    question: cleanTranslation(formData.introQuestion.question) || {
      [lang]: "",
    },
    guide: cleanTranslation(formData.introQuestion.guide),
  },
  branches: formData.branches.map((branch, index) => ({
    ...(branch.id ? { id: branch.id } : {}),
    emoji: {
      ...(branch.emoji.name?.trim()
        ? { name: branch.emoji.name.trim() }
        : {}),
      darkUrl: branch.emoji.darkUrl.trim(),
      ...(branch.emoji.lightUrl?.trim()
        ? { lightUrl: branch.emoji.lightUrl.trim() }
        : {}),
    },
    closedQuestion: {
      question: cleanTranslation(branch.closedQuestion.question) || {
        [lang]: "",
      },
      guide: cleanTranslation(branch.closedQuestion.guide),
      type:
        branch.closedQuestion.type ||
        InAppSurveyClosedQuestionType.MULTIPLE_CHOICE,
      options: branch.closedQuestion.options.map((option) => ({
        ...(option.id ? { id: option.id } : {}),
        icon: option.icon.trim(),
        value: cleanTranslation(option.value) || { [lang]: "" },
      })),
    },
    openQuestion: {
      question: cleanTranslation(branch.openQuestion.question) || {
        [lang]: "",
      },
      guide: cleanTranslation(branch.openQuestion.guide),
    },
    index,
  })),
});
