// src/components/setting/IconManagement.tsx
import { useState, useEffect } from "react";
import { PlusIcon, PencilIcon, TrashIcon } from "@heroicons/react/24/outline";
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
    _id: "",
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
      const response = await iconService.getList();
      setIcons(response.data.items || []);
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
      _id: icon._id,
      url: icon.url,
    });
    setShowForm(true);
  };

  const resetForm = () => {
    setFormData({
      _id: "",
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
    <div>
      <div className="mb-4 flex justify-end">
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Add New Icon
        </button>
      </div>

      {showForm && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {editingIcon ? "Edit Icon" : "Create New Icon"}
          </h2>
          <form onSubmit={handleSubmit}>
            <div className="w-48">
              <div>
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

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="text-gray-500">Loading icons...</div>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          {icons.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              No icons found. Create your first icon to get started.
            </div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Icon
                  </th>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    URL
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
                {icons.map((icon) => (
                  <tr key={icon._id}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="h-10 w-10">
                        {icon.url ? (
                          <img
                            src={icon.url}
                            alt="Icon"
                            className="h-full w-full object-cover"
                            onError={(e) =>
                              (e.currentTarget.style.display = "none")
                            }
                          />
                        ) : null}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 max-w-xs truncate">
                      {icon.url}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => handleEditIcon(icon)}
                        className="text-indigo-600 hover:text-indigo-900 mr-3"
                      >
                        <PencilIcon className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => openDelete(icon)}
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
