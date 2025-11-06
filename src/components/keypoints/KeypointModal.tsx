import React, { useEffect, useState } from "react";
import {
  IKeypoint,
  KeypointPayload,
} from "../../types/interface/keypoint.interface";
import { useSelector } from "react-redux";
import { RootState } from "../../store";

interface Props {
  open: boolean;
  onClose: () => void;
  keypoint: IKeypoint | null;
  onSave: (data: KeypointPayload) => void;
}

const KeypointModal: React.FC<Props> = ({
  open,
  onClose,
  keypoint,
  onSave,
}) => {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [form, setForm] = useState<KeypointPayload>({
    title: "",
    description: "",
    image: "",
    tag: [],
  });

  const [newTag, setNewTag] = useState("");

  useEffect(() => {
    if (keypoint) {
      setForm({
        title: keypoint.title[lang] || "",
        description: keypoint.description?.[lang] || "",
        image: keypoint.image || "",
        tag: keypoint.tag || [],
      });
      setNewTag("");
    } else {
      setForm({
        title: "",
        description: "",
        image: "",
        tag: [],
      });
      setNewTag("");
    }
  }, [keypoint, lang]);

  const handleChange = (field: keyof KeypointPayload, value: any) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const addTag = () => {
    if (newTag.trim()) {
      setForm((prev) => ({
        ...prev,
        tag: [...(prev.tag || []), newTag.trim()],
      }));
      setNewTag("");
    }
  };

  const removeTag = (index: number) => {
    setForm((prev) => ({
      ...prev,
      tag: (prev.tag || []).filter((_, i) => i !== index),
    }));
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      e.preventDefault();
      addTag();
    }
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-40 z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6">
        <h2 className="text-xl font-semibold mb-4">
          {keypoint ? "Edit Keypoint" : "Create Keypoint"}
        </h2>

        <div className="space-y-3">
          {/* Title */}
          <label className="block text-sm font-medium mb-1">Title</label>
          <input
            className="w-full border rounded-lg px-3 py-2"
            placeholder="Title"
            value={form.title}
            onChange={(e) => handleChange("title", e.target.value)}
          />

          {/* Description */}
          <label className="block text-sm font-medium mb-1">Description</label>
          <input
            className="w-full border rounded-lg px-3 py-2"
            placeholder="Description"
            value={form.description}
            onChange={(e) => handleChange("description", e.target.value)}
          />

          {/* Tag */}
          <label className="block text-sm font-medium mb-1">Tags</label>

          {/* Hiển thị các tag hiện có */}
          {form.tag && form.tag.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-2">
              {form.tag.map((tag, index) => (
                <div
                  key={index}
                  className="flex items-center bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm"
                >
                  <span>{tag}</span>
                  <button
                    type="button"
                    className="ml-2 text-blue-600 hover:text-blue-800"
                    onClick={() => removeTag(index)}
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          )}

          {/* Input để thêm tag mới */}
          <div className="flex gap-2">
            <input
              type="text"
              className="flex-1 border rounded-lg px-3 py-2"
              placeholder="Add a tag"
              value={newTag}
              onChange={(e) => setNewTag(e.target.value)}
              onKeyPress={handleKeyPress}
            />
            <button
              type="button"
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
              onClick={addTag}
            >
              Add
            </button>
          </div>

          {/* Image */}
          {/* <label className="block text-sm font-medium mb-1">Image</label>
          <input
            className="w-full border rounded-lg px-3 py-2"
            placeholder="Image url"
            value={form.image}
            onChange={(e) => handleChange("image", e.target.value)}
          /> */}

          {/* Actions */}
          <div className="flex justify-end gap-2 pt-4">
            <button
              className="px-4 py-2 rounded-lg border hover:bg-gray-100"
              onClick={onClose}
            >
              Cancel
            </button>
            <button
              className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700"
              onClick={() => onSave(form)}
            >
              Save
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default KeypointModal;
