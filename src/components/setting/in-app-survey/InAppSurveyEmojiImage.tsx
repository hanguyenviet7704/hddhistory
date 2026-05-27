import { API_URL_V1 } from "../../../services/axiosClient";
import { IInAppSurveyEmoji } from "../../../types/interface/in-app-survey.interface";

interface Props {
  emoji?: IInAppSurveyEmoji;
  label?: string;
  score?: number;
  className?: string;
}

const IMAGE_EXT_REGEX = /\.(png|jpe?g|gif|webp|svg)(\?|#|$)/i;

const buildAssetUrl = (value?: string) => {
  if (!value) return "";
  if (
    value.startsWith("http") ||
    value.startsWith("data:") ||
    value.startsWith("blob:") ||
    value.startsWith("/")
  ) {
    return value;
  }
  if (!IMAGE_EXT_REGEX.test(value)) return value;

  return `${API_URL_V1}/cloudflares/download/${encodeURIComponent(value)}`;
};

const InAppSurveyEmojiImage = ({
  emoji,
  label,
  score,
  className = "h-8 w-8",
}: Props) => {
  const src = buildAssetUrl(emoji?.lightUrl || emoji?.darkUrl);

  if (!src) {
    return (
      <span
        className={`inline-flex items-center justify-center rounded-full bg-amber-50 text-xs font-bold text-amber-700 ${className}`}
        title={label || emoji?.name || `Level ${score || ""}`}
      >
        {score || "?"}
      </span>
    );
  }

  return (
    <img
      src={src}
      alt={label || emoji?.name || `Level ${score || ""}`}
      className={`rounded-full object-cover ${className}`}
    />
  );
};

export default InAppSurveyEmojiImage;
