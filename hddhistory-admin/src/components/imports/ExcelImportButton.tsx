import { AxiosResponse } from "axios";
import { UploadIcon } from "lucide-react";
import React, { useRef, useState } from "react";

import { downloadBlob } from "../../utils/downloadBlob";

type ImportExcelHandler = (file: File) => Promise<AxiosResponse<Blob>>;

interface ExcelImportButtonProps {
  label: string;
  fileName: string;
  importExcel: ImportExcelHandler;
  onSuccess?: () => void;
  onError?: (message: string) => void;
}

const ExcelImportButton: React.FC<ExcelImportButtonProps> = ({
  label,
  fileName,
  importExcel,
  onSuccess,
  onError,
}) => {
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
      const response = await importExcel(file);
      downloadBlob(response.data, resolveFileName(response, fileName));
      onSuccess?.();
    } catch (error: any) {
      onError?.(await getImportErrorMessage(error));
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
        <span>{loading ? "Importing..." : label}</span>
      </button>
    </>
  );
};

function resolveFileName(response: AxiosResponse<Blob>, fallback: string) {
  const disposition = response.headers["content-disposition"];
  const match = disposition?.match(/filename="?([^"]+)"?/i);
  return match?.[1] || fallback;
}

async function getImportErrorMessage(error: any) {
  const data = error?.response?.data;
  if (data instanceof Blob) {
    const text = await data.text();
    try {
      const parsed = JSON.parse(text);
      const firstError = parsed?.errors?.[0];
      if (firstError) {
        return `${firstError.sheet} row ${firstError.row}: ${firstError.message}`;
      }
      return parsed?.message || "Import failed";
    } catch {
      return text || "Import failed";
    }
  }

  return error?.response?.data?.message || error?.message || "Import failed";
}

export default ExcelImportButton;
