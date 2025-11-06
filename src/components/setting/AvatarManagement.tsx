// src/components/setting/AvatarManagement.tsx
import { useState, useEffect } from "react";
import { PlusIcon, PencilIcon, TrashIcon } from "@heroicons/react/24/outline";
import { IAvatar, AvatarPayload } from "../../types/interface/avatar.interface";
import { avatarService } from "../../services/avatarService";
import { useNotification } from "../../utils/hooks/useNotification";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import AvatarConfirm from "./AvatarConfirm";

const AvatarManagement = () => {
  const { showSuccess, showError } = useNotification();

  const [avatars, setAvatars] = useState<IAvatar[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingAvatar, setEditingAvatar] = useState<IAvatar | null>(null);
  const [formData, setFormData] = useState<AvatarPayload>({
    _id: "",
    url: "",
  });
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [selected, setSelected] = useState<IAvatar | null>(null);

  useEffect(() => {
    fetchAvatars();
  }, []);

  const fetchAvatars = async () => {
    try {
      setLoading(true);
      const response = await avatarService.getList();
      setAvatars(response.data.items || []);
    } catch (error) {
      console.error("Error fetching avatars:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateAvatar = async () => {
    try {
      await avatarService.create(formData);
      fetchAvatars();
      resetForm();
      showSuccess("Create avatar successfully");
    } catch (error) {
      console.error("Error creating avatar:", error);
      showError("Failed to save avatar");
    }
  };

  const handleUpdateAvatar = async () => {
    if (!editingAvatar) return;
    try {
      await avatarService.update(editingAvatar._id, formData);
      fetchAvatars();
      resetForm();
      showSuccess("Saved avatar successfully");
    } catch (error) {
      console.error("Error updating avatar:", error);
      showError("Failed to save avatar");
    }
  };

  const handleDeleteAvatar = async (id: string) => {
    try {
      await avatarService.remove(id);
      fetchAvatars();
      setIsConfirmOpen(false);
      setSelected(null);
      showSuccess("Delete avatar successfully");
    } catch (error) {
      showError("Failed to save avatar");
      console.error("Error deleting avatar:", error);
    }
  };

  // Mở modal xác nhận xóa
  const openDelete = (avatar: IAvatar) => {
    setSelected(avatar);
    setIsConfirmOpen(true);
  };

  const handleEditAvatar = (avatar: IAvatar) => {
    setEditingAvatar(avatar);
    setFormData({
      _id: avatar._id,
      url: avatar.url,
    });
    setShowForm(true);
  };

  const resetForm = () => {
    setFormData({
      _id: "",
      url: "",
    });
    setEditingAvatar(null);
    setShowForm(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingAvatar) {
      handleUpdateAvatar();
    } else {
      handleCreateAvatar();
    }
  };

  return (
    <div>
      <div className="mb-4 flex justify-end">
        <button
          onClick={() => setShowForm(true)}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <PlusIcon className="h-5 w-5 mr-2" />
          Add New Avatar
        </button>
      </div>

      {showForm && (
        <div className="mb-6 bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {editingAvatar ? "Edit Avatar" : "Create New Avatar"}
          </h2>
          <form onSubmit={handleSubmit}>
            <div className="w-48">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Avatar Image
                </label>
                <CloudflareFileUpload
                  initialUrl={formData.url}
                  onUrlChange={(newUrl) =>
                    setFormData({ ...formData, url: newUrl })
                  }
                  label=""
                  uploadPayload={{
                    prefix: "",
                    folder: "avatars",
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
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
              >
                {editingAvatar ? "Update" : "Create"}
              </button>
            </div>
          </form>
        </div>
      )}

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="text-gray-500">Loading avatars...</div>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          {avatars.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              No avatars found. Create your first avatar to get started.
            </div>
          ) : (
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th
                    scope="col"
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                  >
                    Avatar
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
                {avatars.map((avatar) => (
                  <tr key={avatar._id}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="h-12 w-12">
                        {avatar.url ? (
                          <img
                            src={avatar.url}
                            alt="Avatar"
                            className="h-full w-full object-cover rounded-full"
                            onError={(e) =>
                              (e.currentTarget.style.display = "none")
                            }
                          />
                        ) : null}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 max-w-xs truncate">
                      {avatar.url}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        onClick={() => handleEditAvatar(avatar)}
                        className="text-indigo-600 hover:text-indigo-900 mr-3"
                      >
                        <PencilIcon className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => openDelete(avatar)}
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
      <AvatarConfirm
        isOpen={isConfirmOpen}
        avatar={selected ?? undefined}
        onClose={() => {
          setIsConfirmOpen(false);
          setSelected(null);
        }}
        onConfirm={() => selected && handleDeleteAvatar(selected._id)}
      />
    </div>
  );
};

export default AvatarManagement;
