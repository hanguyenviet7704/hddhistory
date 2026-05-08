import { UploadIcon } from "lucide-react";
import React, { useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  LearningItemImportTarget,
  courseImportJobService,
} from "../../services/courseImportJobService";

interface AsyncExcelImportButtonProps {
  label: string;
  target: LearningItemImportTarget;
  onError?: (message: string) => void;
}

const AsyncExcelImportButton: React.FC<AsyncExcelImportButtonProps> = ({
  label,
  target,
  onError,
}) => {
  const navigate = useNavigate();
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [loading, setLoading] = useState(false);

  const handleFileChange = async (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;

    setLoading(true);
    try {
      const response = await courseImportJobService.importLearningItems(
        file
      );
      const job = response.data || response;
      navigate(`/course-import-jobs/${job._id}?target=${target}`);
    } catch (error: any) {
      onError?.(error?.response?.data?.message || error?.message || "Import failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <input
        ref={inputRef}
        type="file"
        accept=".xlsx,.xls"
        className="hidden"
        onChange={handleFileChange}
      />
      <button
        type="button"
        disabled={loading}
        onClick={() => inputRef.current?.click()}
        className="inline-flex items-center gap-2 border border-emerald-600 text-emerald-700 hover:bg-emerald-50 disabled:border-emerald-300 disabled:text-emerald-300 px-3 py-2 rounded-lg transition"
      >
        <UploadIcon className="h-4 w-4" />
        <span>{loading ? "Starting..." : label}</span>
      </button>
    </>
  );
};

export default AsyncExcelImportButton;
