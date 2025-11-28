import { useEffect, useState } from "react";
import { PlusIcon, PencilIcon, TrashIcon } from "@heroicons/react/24/outline";
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

const defaultColors = {
  backgroundColor: "#362F82",
  textColor: "#FFFFFF",
};

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
    content: { [lang]: "" },
    ...defaultColors,
  });
  const [confirmDelete, setConfirmDelete] = useState<IQuote | null>(null);

  useEffect(() => {
    fetchQuotes();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    setFormData((prev) => ({
      ...prev,
      content: updateTranslationValue(
        prev.content || {},
        lang,
        prev.content?.[lang] || ""
      ),
    }));
  }, [lang]);

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
    setFormData({
      content: { [lang]: "" },
      ...defaultColors,
    });
    setShowForm(false);
  };

  const handleEdit = (quote: IQuote) => {
    setEditingQuote(quote);
    setFormData({
      content: quote.content || { [lang]: "" },
      backgroundColor: quote.backgroundColor || defaultColors.backgroundColor,
      textColor: quote.textColor || defaultColors.textColor,
    });
    setShowForm(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanedContent = cleanTranslation(
      updateTranslationValue(
        formData.content || {},
        lang,
        formData.content?.[lang] || ""
      )
    ) || { [lang]: "" };

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
      <div className="mb-4 flex justify-end">
        <button
          onClick={() => {
            setShowForm(true);
            setEditingQuote(null);
          }}
          className="flex items-center px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Add Quote
        </button>
      </div>

      {showForm && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {editingQuote ? "Edit Quote" : "Create New Quote"}
          </h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Content ({lang})
              </label>
              <textarea
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                rows={3}
                value={formData.content?.[lang] || ""}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    content: updateTranslationValue(
                      prev.content || {},
                      lang,
                      e.target.value
                    ),
                  }))
                }
                required
              />
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
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
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
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
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
                className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 transition-colors"
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
                        className="text-indigo-600 hover:text-indigo-900 inline-flex items-center"
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
