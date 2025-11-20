// src/components/setting/IconManagement.tsx
import { useState, useEffect } from "react";
import { PlusIcon, TrashIcon } from "@heroicons/react/24/outline";
import { IIcon, IconPayload } from "../../types/interface/icon.interface";
import { iconService } from "../../services/iconService";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import IconConfirm from "./IconConfirm";

const IconManagement = () => {
  const { showSuccess, showError } = useNotification();

  const [icons, setIcons] = useState<IIcon[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingIcon, setEditingIcon] = useState<IIcon | null>(null);
  const [formData, setFormData] = useState<IconPayload>({
    url: "",
  });
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IIcon | null>(null);

  useEffect(() => {
    fetchIcons();
  }, []);

  const fetchIcons = async () => {
    try {
      setLoading(true);
      const response = await iconService.getList({ page: 1, take: 1000 });
      setIcons(response.data.items || response.data || []);
    } catch (error) {
      console.error("Error fetching icons:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateIcon = async () => {
    try {
      await iconService.create(formData);
      fetchIcons();
      resetForm();
      showSuccess("Create icon successfully");
    } catch (error) {
      console.error("Error creating icon:", error);
      showError("Failed to save icon");
    }
  };

  const handleUpdateIcon = async () => {
    if (!editingIcon) return;
    try {
      await iconService.update(editingIcon._id, formData);
      fetchIcons();
      resetForm();
      showSuccess("Saved icon successfully");
    } catch (error) {
      console.error("Error updating icon:", error);
      showError("Failed to save icon");
    }
  };

  const handleDeleteIcon = async (id: string) => {
    try {
      await iconService.remove(id);
      fetchIcons();
      setIsConfirmOpen(false);
      setSelected(null);
      showSuccess("Delete icon successfully");
    } catch (error) {
      showError("Failed to save icon");
      console.error("Error deleting icon:", error);
    }
  };

  // Mở modal xác nhận xóa
  const openDelete = (icon: IIcon) => {
    setSelected(icon);
    setIsConfirmOpen(true);
  };

  const handleEditIcon = (icon: IIcon) => {
    setEditingIcon(icon);
    setFormData({
      url: icon.url,
    });
    setShowForm(true);
  };

  const resetForm = () => {
    setFormData({
      url: "",
    });
    setEditingIcon(null);
    setShowForm(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingIcon) {
      handleUpdateIcon();
    } else {
      handleCreateIcon();
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-xl p-4 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">Icons</h2>
          <button
            onClick={() => {
              resetForm();
              setShowForm((prev) => !prev);
            }}
            className="flex items-center px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
          >
            <PlusIcon className="h-5 w-5 mr-2" />
            {showForm ? "Close form" : "Add New Icon"}
          </button>
        </div>

        {showForm && (
          <div className="border rounded-lg p-4 space-y-4">
            <h2 className="text-lg font-medium text-gray-900">
              {editingIcon ? "Edit Icon" : "Create New Icon"}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="w-48">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Icon Image
                </label>
                <CloudflareFileUpload
                  initialUrl={formData.url}
                  onUrlChange={(newUrl) =>
                    setFormData({ ...formData, url: newUrl })
                  }
                  label=""
                  uploadPayload={{
                    prefix: "",
                    folder: "icons",
                  }}
                />
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
                  className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700 transition-colors"
                >
                  {editingIcon ? "Update" : "Create"}
                </button>
              </div>
            </form>
          </div>
        )}
      </div>

      <div className="bg-white shadow rounded-xl p-4">
        {loading ? (
          <div className="flex justify-center items-center h-64">
            <div className="text-gray-500">Loading icons...</div>
          </div>
        ) : icons.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            No icons found. Create your first icon to get started.
          </div>
        ) : (
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {icons.map((icon) => (
              <div
                key={icon._id}
                className="border rounded-lg p-3 flex items-start gap-3"
              >
                <div className="h-12 w-12 flex-shrink-0">
                  {icon.url && (
                    <img
                      src={icon.url}
                      alt="Icon"
                      className="h-full w-full object-cover rounded"
                    />
                  )}
                </div>
                <div className="flex-1">
                  <div className="mt-1 flex gap-2">
                    <button
                      onClick={() => handleEditIcon(icon)}
                      className="px-3 py-1 text-sm bg-gray-100 rounded"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => openDelete(icon)}
                      className="px-3 py-1 text-sm bg-red-100 text-red-600 rounded inline-flex items-center gap-1"
                      disabled={loading}
                    >
                      <TrashIcon className="h-4 w-4" /> Delete
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      <IconConfirm
        isOpen={isConfirmOpen}
        icon={selected ?? undefined}
        onClose={() => {
          setIsConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={() => selected && handleDeleteIcon(selected._id)}
      />
    </div>
  );
};

export default IconManagement;
