import { LangCode } from "../types/enum/common.enum";
import { ITranslation } from "./translate";

export type EstimateCompleteTimeUnit = "minute" | "hour";

export interface EstimateCompleteTimeInput {
  amount: string;
  unit: EstimateCompleteTimeUnit;
}

const HOUR_PATTERN = /(giờ|hour|hours|hr|hrs|小时|小時|時間|시간)/i;
const MINUTE_PATTERN = /(phút|minute|minutes|min|mins|分钟|分鐘|分|분)/i;

const isPositiveNumber = (value: unknown): value is number =>
  typeof value === "number" && Number.isFinite(value) && value > 0;

const parseAmountFromLabel = (label: string): number | undefined => {
  const match = label.match(/(\d+(?:[.,]\d+)?)/);
  if (!match) return undefined;

  const parsed = Number(match[1].replace(",", "."));
  return isPositiveNumber(parsed) ? parsed : undefined;
};

const inferUnitFromLabel = (
  label?: string
): EstimateCompleteTimeUnit | undefined => {
  if (!label) return undefined;
  if (HOUR_PATTERN.test(label)) return "hour";
  if (MINUTE_PATTERN.test(label)) return "minute";
  return undefined;
};

const formatAmount = (amount: number): string =>
  Number.isInteger(amount) ? String(amount) : String(Number(amount.toFixed(2)));

export const getEstimateCompleteTimeUnitLabel = (
  unit: EstimateCompleteTimeUnit,
  lang: LangCode,
  amount?: number
): string => {
  if (lang === LangCode.VI) {
    return unit === "hour" ? "giờ" : "phút";
  }

  if (lang === LangCode.ZH) {
    return unit === "hour" ? "小时" : "分钟";
  }

  if (lang === LangCode.JA) {
    return unit === "hour" ? "時間" : "分";
  }

  if (lang === LangCode.KO) {
    return unit === "hour" ? "시간" : "분";
  }

  if (unit === "hour") {
    return amount === 1 ? "hour" : "hours";
  }

  return amount === 1 ? "minute" : "minutes";
};

export const parseEstimateCompleteTimeInput = (
  estimateCompleTime: ITranslation | undefined,
  estimateCompleTimeNumber: number | undefined,
  lang: LangCode
): EstimateCompleteTimeInput => {
  const localizedLabel = estimateCompleTime?.[lang]?.trim() || "";
  const unitFromLabel = inferUnitFromLabel(localizedLabel);
  const amountFromLabel = parseAmountFromLabel(localizedLabel);

  const numberUnit: EstimateCompleteTimeUnit =
    isPositiveNumber(estimateCompleTimeNumber) &&
    estimateCompleTimeNumber >= 60 &&
    estimateCompleTimeNumber % 60 === 0
      ? "hour"
      : "minute";

  const resolvedUnit = unitFromLabel || numberUnit;

  if (amountFromLabel !== undefined) {
    return {
      amount: formatAmount(amountFromLabel),
      unit: resolvedUnit,
    };
  }

  if (!isPositiveNumber(estimateCompleTimeNumber)) {
    return {
      amount: "",
      unit: resolvedUnit,
    };
  }

  const amount =
    resolvedUnit === "hour"
      ? estimateCompleTimeNumber / 60
      : estimateCompleTimeNumber;

  return {
    amount: formatAmount(amount),
    unit: resolvedUnit,
  };
};

export const buildEstimateCompleteTimeValue = (
  amountInput: string,
  unit: EstimateCompleteTimeUnit,
  lang: LangCode
): {
  label: string;
  estimateCompleTimeNumber: number | undefined;
} => {
  const parsedAmount = Number(amountInput);
  if (!isPositiveNumber(parsedAmount)) {
    return { label: "", estimateCompleTimeNumber: undefined };
  }

  const normalizedAmount = Math.max(1, Math.floor(parsedAmount));
  const estimateCompleTimeNumber =
    unit === "hour" ? normalizedAmount * 60 : normalizedAmount;
  const unitLabel = getEstimateCompleteTimeUnitLabel(
    unit,
    lang,
    normalizedAmount
  );

  return {
    label: `${normalizedAmount} ${unitLabel}`,
    estimateCompleTimeNumber,
  };
};

export const formatEstimateCompleteTimeLabel = (
  estimateCompleTime: ITranslation | undefined,
  estimateCompleTimeNumber: number | undefined,
  lang: LangCode
): string => {
  const parsed = parseEstimateCompleteTimeInput(
    estimateCompleTime,
    estimateCompleTimeNumber,
    lang
  );

  if (!parsed.amount) return "";

  return `${parsed.amount} ${getEstimateCompleteTimeUnitLabel(
    parsed.unit,
    lang,
    Number(parsed.amount)
  )}`;
};
