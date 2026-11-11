import React, { useEffect, useState } from "react";
import { PlusIcon, TrashIcon } from "@heroicons/react/24/outline";
import { useNotification } from "../../utils/hooks/useNotification";
import { avatarService } from "../../services/avatarService";
import { IAvatar } from "../../types/interface/avatar.interface";
import CloudflareFileUpload from "../files/CloudflareFileUpload";
import AvatarConfirm from "./AvatarConfirm";

interface AvatarFormState {
  _id?: string;
  name: string;
  url: string;
}

const emptyAvatar = (): AvatarFormState => ({
  name: "",
  url: "",
});

const AvatarManagement: React.FC = () => {
  const { showSuccess, showError } = useNotification();
  const [avatars, setAvatars] = useState<IAvatar[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<AvatarFormState>(emptyAvatar());
  const [deleteTarget, setDeleteTarget] = useState<IAvatar | null>(null);

  const fetchAvatars = async () => {
    try {
      setLoading(true);
      const res = await avatarService.getList({ page: 1, take: 1000 });
      const list: IAvatar[] = res.data?.items || res.data || [];
      setAvatars(list);
    } catch (err) {
      console.error(err);
      showError("Failed to load avatars");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAvatars();
  }, []);

  const resetForm = () => setForm(emptyAvatar());

  const handleSave = async () => {
    const trimmedName = form.name.trim();
    const trimmedUrl = form.url.trim();

    if (!trimmedName || !trimmedUrl) {
      showError("Please provide both name and image URL");
      return;
    }

    try {
      setSaving(true);
      const payload = { name: trimmedName, url: trimmedUrl };

      if (form._id) {
        await avatarService.update(form._id, payload);
        showSuccess("Avatar updated");
      } else {
        await avatarService.create(payload);
        showSuccess("Avatar created");
      }

      resetForm();
      setShowForm(false);
      fetchAvatars();
    } catch (err) {
      console.error(err);
      showError("Failed to save avatar");
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (avatar: IAvatar) => {
    setForm({
      _id: avatar._id,
      name: avatar.name || "",
      url: avatar.url || "",
    });
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (!id) return;
    try {
      setSaving(true);
      await avatarService.remove(id);
      showSuccess("Avatar deleted");
      if (form._id === id) {
        resetForm();
        setShowForm(false);
      }
      fetchAvatars();
    } catch (err) {
      console.error(err);
      showError("Failed to delete avatar");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-xl p-4 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">Avatars</h2>
          <div className="flex gap-2">
            <button
              className="flex items-center gap-2 text-sm px-3 py-2 bg-brand-600 text-white rounded-lg"
              onClick={() => {
                resetForm();
                setShowForm((prev) => !prev);
              }}
            >
              <PlusIcon className="h-4 w-4" />
              {showForm ? "Close form" : "New Avatar"}
            </button>
          </div>
        </div>

        {showForm && (
          <div className="border rounded-lg p-4 space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-3">
                <label className="block text-sm font-medium text-gray-700">
                  Name
                </label>
                <input
                  className="border rounded-lg px-3 py-2 w-full focus:outline-none focus:ring-2 focus:ring-brand-500"
                  placeholder="Enter avatar name"
                  value={form.name}
                  onChange={(e) =>
                    setForm((prev) => ({ ...prev, name: e.target.value }))
                  }
                />
              </div>

              <div className="space-y-3">
                <label className="block text-sm font-medium text-gray-700">
                  Image URL
                </label>
                <CloudflareFileUpload
                  initialUrl={form.url}
                  onUrlChange={(url) => setForm((prev) => ({ ...prev, url }))}
                  label="Upload image"
                  uploadPayload={{ prefix: "", folder: "avatars" }}
                />
              </div>
            </div>

            <div className="flex gap-2">
              <button
                className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg disabled:opacity-60"
                onClick={handleSave}
                disabled={saving}
              >
                <PlusIcon className="h-5 w-5" />
                {form._id ? "Update" : "Create"}
              </button>
              {form._id && (
                <button
                  className="px-4 py-2 bg-gray-200 rounded-lg"
                  onClick={() => {
                    resetForm();
                    setShowForm(false);
                  }}
                  disabled={saving}
                >
                  Cancel edit
                </button>
              )}
            </div>
          </div>
        )}
      </div>

      <div className="bg-white shadow rounded-xl p-4">
        {loading ? (
          <div className="text-center py-6 text-gray-500">Loading...</div>
        ) : avatars.length === 0 ? (
          <div className="text-center py-6 text-gray-500">No avatars found</div>
        ) : (
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {avatars.map((avatar) => (
              <div
                key={avatar._id}
                className="border rounded-lg p-3 flex items-start gap-3"
              >
                <img
                  src={avatar.url}
                  alt={avatar.name}
                  className="w-16 h-16 object-cover rounded"
                />
                <div className="flex-1">
                  <div className="font-semibold">{avatar.name}</div>
                  <div className="mt-2 flex gap-2">
                    <button
                      className="px-3 py-1 text-sm bg-gray-100 rounded"
                      onClick={() => handleEdit(avatar)}
                    >
                      Edit
                    </button>
                    <button
                      className="px-3 py-1 text-sm bg-red-100 text-red-600 rounded inline-flex items-center gap-1"
                      onClick={() => setDeleteTarget(avatar)}
                      disabled={saving}
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

      <AvatarConfirm
        isOpen={!!deleteTarget}
        avatar={deleteTarget || undefined}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget?._id) {
            handleDelete(deleteTarget._id);
          }
          setDeleteTarget(null);
        }}
      />
    </div>
  );
};

export default AvatarManagement;
