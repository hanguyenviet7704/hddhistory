// src/pages/settings/TagManagement.tsx
import { useState, useEffect } from "react";
import { PlusIcon, PencilIcon, TrashIcon } from "@heroicons/react/24/outline";
import { TagPayload, ITag } from "../../types/interface/tag.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { tagService } from "../../services/tagService";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import TagConfirm from "./TagConfirm";

const TagManagement = () => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [tags, setTags] = useState<ITag[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingTag, setEditingTag] = useState<ITag | null>(null);
  const [formData, setFormData] = useState<TagPayload>({
    _id: "",
    title: "",
    color: "#3B82F6",
    url: "",
  });
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<ITag | null>(null);

  useEffect(() => {
    fetchTags();
  }, []);

  const fetchTags = async () => {
    try {
      setLoading(true);
      const response = await tagService.getList({ page: 1, take: 1000 });
      setTags(response.data.items || response.data || []);
    } catch (error) {
      console.error("Error fetching tags:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateTag = async () => {
    try {
      await tagService.create(formData);
      fetchTags();
      resetForm();
      showSuccess("Create tag successfully");
    } catch (error) {
      console.error("Error creating tag:", error);
      showError("Failed to save tag");
    }
  };

  const handleUpdateTag = async () => {
    if (!editingTag) return;
    try {
      await tagService.update(editingTag._id, formData);
      fetchTags();
      resetForm();
      showSuccess("Saved tag successfully");
    } catch (error) {
      console.error("Error updating tag:", error);
      showError("Failed to save tag");
    }
  };

  const handleDeleteTag = async (id: string) => {
    try {
      await tagService.remove(id);
      fetchTags();
      setIsConfirmOpen(false);
      setSelected(null);
      showSuccess("Delete tag successfully");
    } catch (error) {
      showError("Failed to save tag");
      console.error("Error deleting tag:", error);
    }
  };

  // Mở modal xác nhận xóa
  const openDelete = (t: ITag) => {
    setSelected(t);
    setIsConfirmOpen(true);
  };

  const handleEditTag = (tag: ITag) => {
    setEditingTag(tag);
    const titleValue = tag.title[lang] || "";

    setFormData({
      _id: tag._id,
      title: titleValue,
      color: tag.color,
      url: tag.url,
    });
    setShowForm(true);
  };

  const resetForm = () => {
    setFormData({
      _id: "",
      title: "",
      color: "#3B82F6",
      url: "",
    });
    setEditingTag(null);
    setShowForm(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingTag) {
      handleUpdateTag();
    } else {
      handleCreateTag();
    }
  };

  return (
    <div>
      <div className="mb-4 flex justify-end">
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Add New Tag
        </button>
      </div>

      {showForm && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {editingTag ? "Edit Tag" : "Create New Tag"}
          </h2>
          <form onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label
                  htmlFor="title"
                  className="block text-sm font-medium text-gray-700 mb-1"
                >
                  Title
                </label>
                <input
                  type="text"
                  id="title"
                  value={formData.title}
                  onChange={(e) =>
                    setFormData({ ...formData, title: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                  required
                />
              </div>
              <div>
                <label
                  htmlFor="color"
                  className="block text-sm font-medium text-gray-700 mb-1"
                >
                  Color
                </label>
                <div className="flex items-center">
                  <input
                    type="color"
                    id="color"
                    value={formData.color}
                    onChange={(e) =>
                      setFormData({ ...formData, color: e.target.value })
                    }
                    className="h-10 w-20 border border-gray-300 rounded-md cursor-pointer"
                  />
                  <input
                    type="text"
                    value={formData.color}
                    onChange={(e) =>
                      setFormData({ ...formData, color: e.target.value })
                    }
                    className="ml-2 flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Icon
                </label>
                {/* ĐÃ THAY THẾ BẰNG CloudflareFileUpload */}
                <CloudflareFileUpload
                  initialUrl={formData.url}
                  onUrlChange={(newUrl) =>
                    setFormData({ ...formData, url: newUrl })
                  }
                  label=""
                  uploadPayload={{
                    prefix: "",
                    folder: "tags",
                  }}
                />
              </div>
            </div>
            <div className="mt-4 flex justify-end space-x-2">
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors"
              >
                {editingTag ? "Update" : "Create"}
              </button>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="text-gray-500">Loading tags...</div>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          {tags.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              No tags found. Create your first tag to get started.
            </div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Tag
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Title
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Color
                  </th>
                  <th
                    scope="col"
                    className="relative px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {tags.map((tag) => (
                  <tr key={tag._id}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="h-8 w-8">
                        {tag.url ? (
                          <img
                            src={tag.url}
                            alt={tag.title[lang] || ""}
                            className="h-full w-full object-cover"
                            // Khi ảnh bị lỗi, ẩn ảnh đi
                            onError={(e) =>
                              (e.currentTarget.style.display = "none")
                            }
                          />
                        ) : null}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {tag.title[lang]}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div
                          className="h-6 w-6 rounded border border-gray-300"
                          style={{ backgroundColor: tag.color }}
                        ></div>
                        <span className="ml-2 text-sm text-gray-500">
                          {tag.color}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => handleEditTag(tag)}
                        className="text-indigo-600 hover:text-indigo-900 mr-3"
                      >
                        <PencilIcon className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => openDelete(tag)}
                        className="text-red-600 hover:text-red-900"
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
      <TagConfirm
        isOpen={isConfirmOpen}
        tag={selected ?? undefined}
        onClose={() => {
          setIsConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={() => selected && handleDeleteTag(selected._id)}
      />
    </div>
  );
};

export default TagManagement;
