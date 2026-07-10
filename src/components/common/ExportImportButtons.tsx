import React, { useRef, useState } from "react";
import { DownloadIcon, UploadIcon, XIcon, Loader2Icon } from "lucide-react";
import { useNotification } from "../../utils/hooks/useNotification";

const BACKEND_URL = process.env.REACT_APP_BACKEND_AI_TUTOR || "(unknown backend)";

// Report shape is intentionally loose — the backend returns different keys for
// reanchor vs habit; we render numbers as a summary and arrays as detail lists.
type ImportReport = Record<string, unknown>;

interface Props {
  /** Human label, e.g. "re-anchor reasons" or "habits". */
  label: string;
  /** Fetch current data and trigger the .xlsx download. */
  onExport: () => Promise<void>;
  /** Parse a chosen .xlsx file into portable rows. */
  onParse: (file: File) => Promise<any[]>;
  /** Send parsed rows to the backend import endpoint; returns the report. */
  onImport: (rows: any[]) => Promise<ImportReport>;
  /** Called after a successful import so the page can refresh. */
  onImported?: () => void;
}

const numberFields = (report: ImportReport) =>
  Object.entries(report).filter(([, v]) => typeof v === "number") as [
    string,
    number,
  ][];

const listFields = (report: ImportReport) =>
  Object.entries(report).filter(
    ([, v]) => Array.isArray(v) && (v as unknown[]).length > 0,
  ) as [string, unknown[]][];

const ExportImportButtons: React.FC<Props> = ({
  label,
  onExport,
  onParse,
  onImport,
  onImported,
}) => {
  const { showSuccess, showError } = useNotification();
  const fileRef = useRef<HTMLInputElement>(null);

  const [exporting, setExporting] = useState(false);
  const [importing, setImporting] = useState(false);
  const [pendingRows, setPendingRows] = useState<any[] | null>(null);
  const [pendingName, setPendingName] = useState("");
  const [report, setReport] = useState<ImportReport | null>(null);

  const handleExport = async () => {
    setExporting(true);
    try {
      await onExport();
      showSuccess(`Exported ${label}.`);
    } catch (e: any) {
      showError(e?.message || `Failed to export ${label}.`);
    } finally {
      setExporting(false);
    }
  };

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = ""; // allow re-selecting the same file
    if (!file) return;
    try {
      const rows = await onParse(file);
      if (!rows.length) {
        showError("No valid rows found in that file.");
        return;
      }
      setPendingRows(rows);
      setPendingName(file.name);
    } catch (err: any) {
      showError(err?.message || "Could not read that .xlsx file.");
    }
  };

  const confirmImport = async () => {
    if (!pendingRows) return;
    setImporting(true);
    try {
      const result = await onImport(pendingRows);
      setPendingRows(null);
      setReport(result || {});
      showSuccess(`Imported ${label}.`);
      onImported?.();
    } catch (e: any) {
      showError(
        e?.response?.data?.message || e?.message || `Failed to import ${label}.`,
      );
    } finally {
      setImporting(false);
    }
  };

  return (
    <>
      <button
        onClick={handleExport}
        disabled={exporting}
        className="inline-flex items-center gap-2 border border-gray-300 bg-white text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition disabled:opacity-50"
        title={`Export ${label} to .xlsx`}
      >
        {exporting ? (
          <Loader2Icon className="h-5 w-5 animate-spin" />
        ) : (
          <DownloadIcon className="h-5 w-5" />
        )}
        <span>Export</span>
      </button>

      <button
        onClick={() => fileRef.current?.click()}
        className="inline-flex items-center gap-2 border border-gray-300 bg-white text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition"
        title={`Import ${label} from .xlsx`}
      >
        <UploadIcon className="h-5 w-5" />
        <span>Import</span>
      </button>
      <input
        ref={fileRef}
        type="file"
        accept=".xlsx"
        className="hidden"
        onChange={handleFile}
      />

      {/* Confirm dialog */}
      {pendingRows && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full p-6">
            <div className="flex items-start justify-between mb-3">
              <h3 className="text-lg font-bold">Confirm import</h3>
              <button
                onClick={() => setPendingRows(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XIcon className="h-5 w-5" />
              </button>
            </div>
            <p className="text-sm text-gray-600 mb-2">
              About to import <b>{pendingRows.length}</b> {label} rows from{" "}
              <span className="font-mono">{pendingName}</span> into:
            </p>
            <p className="text-sm font-mono bg-gray-100 rounded px-2 py-1 mb-3 break-all">
              {BACKEND_URL}
            </p>
            <p className="text-sm text-red-600 mb-4">
              This <b>replaces</b> existing {label} for every course/keypoint in
              the file. Courses/keypoints not in the file are left untouched.
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setPendingRows(null)}
                className="px-4 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={confirmImport}
                disabled={importing}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:from-blue-700 hover:to-indigo-700 disabled:opacity-50"
              >
                {importing && <Loader2Icon className="h-4 w-4 animate-spin" />}
                <span>Replace &amp; import</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Result dialog */}
      {report && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full p-6 max-h-[85vh] overflow-auto">
            <div className="flex items-start justify-between mb-3">
              <h3 className="text-lg font-bold">Import result</h3>
              <button
                onClick={() => setReport(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="grid grid-cols-2 gap-2 mb-4">
              {numberFields(report).map(([k, v]) => (
                <div
                  key={k}
                  className="flex items-center justify-between bg-gray-50 rounded px-3 py-2"
                >
                  <span className="text-sm text-gray-600">{k}</span>
                  <span className="text-sm font-bold">{v}</span>
                </div>
              ))}
            </div>
            {listFields(report).map(([k, arr]) => (
              <div key={k} className="mb-3">
                <div className="text-sm font-semibold text-gray-700 mb-1">
                  {k} ({arr.length})
                </div>
                <ul className="text-xs text-gray-600 bg-gray-50 rounded p-2 max-h-40 overflow-auto list-disc list-inside">
                  {arr.map((item, i) => (
                    <li key={i} className="break-all">
                      {typeof item === "string" ? item : JSON.stringify(item)}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
            <div className="flex justify-end">
              <button
                onClick={() => setReport(null)}
                className="px-4 py-2 rounded-lg bg-gray-800 text-white hover:bg-gray-900"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default ExportImportButtons;
