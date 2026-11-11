import { useEffect, useState } from "react";
import {
  PlusIcon,
  PencilIcon,
  TrashIcon,
  ArrowUpTrayIcon,
} from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import {
  IQuote,
  QuotePayload,
  QuoteListQuery,
} from "../../types/interface/quote.interface";
import { quoteService } from "../../services/quoteService";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  cleanTranslation,
  getTranslationValue,
  updateTranslationValue,
} from "../../utils/translation";
import { LangCode } from "../../types/enum/common.enum";
import { ITranslation } from "../../utils/translate";
import ExportImportButtons from "../common/ExportImportButtons";
import {
  downloadQuotesXlsx,
  parseQuotesXlsx,
  ParsedQuoteRow,
} from "../../utils/quoteXlsx";

const defaultColors = {
  backgroundColor: "#362F82",
  textColor: "#FFFFFF",
};

/// Every locale a quote can carry, English FIRST because it is the fallback:
/// the dispatcher resolves `translations[userLang] || translations.en`, so a
/// quote missing the user's language still reads in English — but one missing
/// ENGLISH resolves to '' and `resolveContext` returns null, which silently
/// drops that user's daily reminder altogether.
const QUOTE_LANGS: { code: LangCode; label: string }[] = [
  { code: "en" as LangCode, label: "EN" },
  { code: "vi" as LangCode, label: "VI" },
  { code: "zh" as LangCode, label: "ZH" },
  { code: "ja" as LangCode, label: "JA" },
  { code: "ko" as LangCode, label: "KO" },
];

const normalizeQuoteList = (payload: any): IQuote[] => {
  const data = payload?.data ?? payload ?? {};
  const list =
    data.items ??
    data.list ??
    data.data?.items ??
    data.data?.list ??
    (Array.isArray(data) ? data : []);
  return Array.isArray(list) ? list : [];
};

const QuoteManagement = () => {
  const lang = useSelector((state: RootState) => state.lang.code) as LangCode;
  const { showSuccess, showError } = useNotification();

  const [quotes, setQuotes] = useState<IQuote[]>([]);
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editingQuote, setEditingQuote] = useState<IQuote | null>(null);
  const [formData, setFormData] = useState<QuotePayload>({
    content: {},
    ...defaultColors,
  });
  const [confirmDelete, setConfirmDelete] = useState<IQuote | null>(null);
  const [showImport, setShowImport] = useState(false);
  const [importText, setImportText] = useState("");
  const [importing, setImporting] = useState(false);

  useEffect(() => {
    fetchQuotes();
  }, []);

  const fetchQuotes = async () => {
    try {
      setLoading(true);
      const res = await quoteService.getList(
        new QuoteListQuery({ page: 1, take: 100 })
      );
      const list = normalizeQuoteList(res);
      setQuotes(list);
    } catch (err) {
      console.error("Failed to fetch quotes", err);
      showError("Tải danh sách quote thất bại");
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setEditingQuote(null);
    setFormData({ content: {}, ...defaultColors });
    setShowForm(false);
  };

  const handleEdit = (quote: IQuote) => {
    setEditingQuote(quote);
    setFormData({
      content: quote.content || {},
      backgroundColor: quote.backgroundColor || defaultColors.backgroundColor,
      textColor: quote.textColor || defaultColors.textColor,
    });
    setShowForm(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanedContent = cleanTranslation(formData.content || {}) || {};
    if (!cleanedContent.en?.trim()) {
      showError("Cần ít nhất bản tiếng Anh — đó là bản fallback cho mọi ngôn ngữ khác");
      return;
    }

    const payload: QuotePayload = {
      content: cleanedContent,
      backgroundColor:
        formData.backgroundColor || defaultColors.backgroundColor,
      textColor: formData.textColor || defaultColors.textColor,
    };

    try {
      if (editingQuote?._id) {
        await quoteService.update(editingQuote._id, payload);
        showSuccess("Cập nhật quote thành công");
      } else {
        await quoteService.create(payload);
        showSuccess("Tạo quote thành công");
      }
      resetForm();
      fetchQuotes();
    } catch (err) {
      console.error("Failed to save quote", err);
      showError("Lưu quote thất bại");
    }
  };



  /// Creates every parsed row that is not already stored, and reports the split.
  ///
  /// Shared by the JSON paste box and the Excel importer so the two cannot drift
  /// on what "already exists" means. One POST per quote — the API has no bulk
  /// route — and duplicates are matched on the English line, which makes a
  /// re-run after a partial failure safe rather than doubling what landed.
  const createMissingQuotes = async (
    rows: { content?: ITranslation; backgroundColor?: string; textColor?: string }[]
  ) => {
    const existing = new Set(
      quotes.map((quote) => (quote.content?.en || "").trim()).filter(Boolean)
    );

    let created = 0;
    let skipped = 0;
    let failed = 0;

    for (const row of rows) {
      const content = cleanTranslation(row?.content || {}) || {};
      const english = (content.en || "").trim();
      if (!english) {
        failed += 1;
        continue;
      }
      if (existing.has(english)) {
        skipped += 1;
        continue;
      }
      try {
        await quoteService.create({
          content,
          backgroundColor: row?.backgroundColor || defaultColors.backgroundColor,
          textColor: row?.textColor || defaultColors.textColor,
        });
        existing.add(english);
        created += 1;
      } catch (err) {
        console.error("Failed to import quote", english, err);
        failed += 1;
      }
    }

    return { created, skipped, failed };
  };

  /// Bulk-create from a pasted JSON array — the shape `quotes-seed.json` uses,
  /// so a batch prepared elsewhere goes in without retyping.
  const handleImport = async () => {
    let parsed: any;
    try {
      parsed = JSON.parse(importText);
    } catch (err) {
      showError("JSON không hợp lệ");
      return;
    }
    const rows: any[] = Array.isArray(parsed) ? parsed : parsed?.quotes;
    if (!Array.isArray(rows) || rows.length === 0) {
      showError("Cần một mảng quote, hoặc { quotes: [...] }");
      return;
    }

    setImporting(true);
    let result = { created: 0, skipped: 0, failed: 0 };
    try {
      result = await createMissingQuotes(rows);
    } finally {
      setImporting(false);
    }

    // Reported even when some failed: a silent partial import is how you end up
    // believing all 30 landed when 6 did not.
    const summary = `Đã thêm ${result.created}, bỏ qua ${result.skipped} (đã có), lỗi ${result.failed}`;
    result.failed ? showError(summary) : showSuccess(summary);
    setImportText("");
    setShowImport(false);
    fetchQuotes();
  };

  /// Excel path. Parsing and creating stay separate so the shared
  /// [ExportImportButtons] can show the parsed row count for confirmation before
  /// anything is written — an import of the wrong sheet is caught there rather
  /// than after 30 POSTs.
  const handleParseExcel = async (file: File): Promise<ParsedQuoteRow[]> =>
    parseQuotesXlsx(file);

  const handleImportExcel = async (rows: ParsedQuoteRow[]) =>
    createMissingQuotes(rows);

  const handleDelete = async () => {
    if (!confirmDelete?._id) return;
    try {
      await quoteService.remove(confirmDelete._id);
      showSuccess("Xoá quote thành công");
      setConfirmDelete(null);
      fetchQuotes();
    } catch (err) {
      console.error("Failed to delete quote", err);
      showError("Xoá quote thất bại");
    }
  };

  const renderColorPreview = (quote: IQuote) => (
    <div className="flex items-center gap-2">
      <span
        className="inline-flex h-6 w-6 rounded border border-gray-200"
        style={{ backgroundColor: quote.backgroundColor }}
        title={`Background: ${quote.backgroundColor}`}
      />
      <span
        className="inline-flex h-6 w-6 rounded border border-gray-200"
        style={{ backgroundColor: quote.textColor }}
        title={`Text: ${quote.textColor}`}
      />
    </div>
  );

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center justify-end gap-2">
        <ExportImportButtons
          label="quotes"
          onExport={async () => downloadQuotesXlsx(quotes)}
          onParse={handleParseExcel}
          onImport={handleImportExcel}
          onImported={fetchQuotes}
        />
        <button
          onClick={() => setShowImport((open) => !open)}
          className="flex items-center px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
        >
          <ArrowUpTrayIcon className="h-5 w-5 mr-2" />
          Import JSON
        </button>
        <button
          onClick={() => {
            setShowForm(true);
            setEditingQuote(null);
          }}
          className="flex items-center px-4 py-2 bg-bronze-600 text-white rounded-lg hover:bg-bronze-700 transition-colors"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Add Quote
        </button>
      </div>

      {showImport && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 mb-1">Import JSON</h2>
          <p className="text-sm text-gray-500 mb-3">
            Dán một mảng{" "}
            <code className="text-xs">
              {'[{ "content": { "en": "...", "vi": "..." }, "backgroundColor": "#362F82", "textColor": "#FFFFFF" }]'}
            </code>
            . Câu nào trùng dòng EN đã có sẽ được bỏ qua, nên chạy lại nhiều lần
            không bị nhân đôi.
          </p>
          <textarea
            className="w-full px-3 py-2 border border-gray-300 rounded-md font-mono text-xs focus:outline-none focus:ring-2 focus:ring-bronze-500"
            rows={10}
            value={importText}
            onChange={(e) => setImportText(e.target.value)}
            placeholder='[{ "content": { "en": "A little every day beats a lot once in a while." } }]'
          />
          <div className="mt-3 flex justify-end gap-2">
            <button
              type="button"
              onClick={() => {
                setShowImport(false);
                setImportText("");
              }}
              disabled={importing}
              className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-60"
            >
              Huỷ
            </button>
            <button
              type="button"
              onClick={handleImport}
              disabled={importing || !importText.trim()}
              className="px-4 py-2 bg-bronze-600 text-white rounded-lg hover:bg-bronze-700 disabled:opacity-60"
            >
              {importing ? "Đang import..." : "Import"}
            </button>
          </div>
        </div>
      )}

      {showForm && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {editingQuote ? "Edit Quote" : "Create New Quote"}
          </h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Every locale at once. The old form showed only the admin's
                current display language, so filling a quote in five languages
                meant saving it, switching the header language, reopening it,
                and saving again — five times per quote, with no way to see
                which locale was still blank. */}
            <div className="space-y-2">
              <label className="block text-sm font-medium text-gray-700">
                Content
              </label>
              {QUOTE_LANGS.map(({ code, label }) => {
                const isFallback = code === ("en" as LangCode);
                return (
                  <div key={code} className="flex gap-2">
                    <span
                      className={`mt-2 w-10 shrink-0 text-xs font-semibold ${
                        isFallback ? "text-bronze-600" : "text-gray-400"
                      }`}
                      title={
                        isFallback
                          ? "Bắt buộc — bản fallback khi user dùng ngôn ngữ chưa dịch"
                          : undefined
                      }
                    >
                      {label}
                      {isFallback ? " *" : ""}
                    </span>
                    <textarea
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
                      rows={2}
                      value={formData.content?.[code] || ""}
                      placeholder={
                        isFallback ? "Bắt buộc" : "Để trống sẽ dùng bản EN"
                      }
                      onChange={(e) =>
                        setFormData((prev) => ({
                          ...prev,
                          content: updateTranslationValue(
                            prev.content || {},
                            code,
                            e.target.value
                          ),
                        }))
                      }
                    />
                  </div>
                );
              })}
              <p className="text-xs text-gray-500">
                Chỉ EN là bắt buộc: user ở ngôn ngữ chưa dịch sẽ đọc bản EN.
                Thiếu EN thì user đó không nhận được nhắc nhở nào cả.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Background Color
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={formData.backgroundColor}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        backgroundColor: e.target.value,
                      }))
                    }
                    className="h-10 w-16 border border-gray-200 rounded"
                  />
                  <input
                    type="text"
                    value={formData.backgroundColor}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        backgroundColor: e.target.value,
                      }))
                    }
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Text Color
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={formData.textColor}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        textColor: e.target.value,
                      }))
                    }
                    className="h-10 w-16 border border-gray-200 rounded"
                  />
                  <input
                    type="text"
                    value={formData.textColor}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        textColor: e.target.value,
                      }))
                    }
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
                  />
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-bronze-600 text-white rounded-md hover:bg-bronze-700 transition-colors"
              >
                {editingQuote ? "Update" : "Create"}
              </button>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="text-gray-500">Loading quotes...</div>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          {quotes.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              No quotes found. Create your first quote to get started.
            </div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Content
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Colors
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {quotes.map((quote) => (
                  <tr key={quote._id}>
                    <td className="px-6 py-4 text-sm text-gray-900">
                      {getTranslationValue(quote.content, lang) || "—"}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-700">
                      {renderColorPreview(quote)}
                    </td>
                    <td className="px-6 py-4 text-right text-sm font-medium space-x-2">
                      <button
                        onClick={() => handleEdit(quote)}
                        className="text-bronze-600 hover:text-bronze-900 inline-flex items-center"
                      >
                        <PencilIcon className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => setConfirmDelete(quote)}
                        className="text-red-600 hover:text-red-900 inline-flex items-center"
                      >
                        <TrashIcon className="h-5 w-5" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {confirmDelete && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="bg-white rounded-lg shadow-lg w-full max-w-md p-6 relative">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Xoá quote
            </h3>
            <p className="text-sm text-gray-600 mb-6">
              Bạn có chắc muốn xoá quote này?
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setConfirmDelete(null)}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Huỷ
              </button>
              <button
                onClick={handleDelete}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
              >
                Xoá
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default QuoteManagement;
