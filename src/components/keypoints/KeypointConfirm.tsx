import React, { useState } from "react";
import { XMarkIcon } from "@heroicons/react/24/outline";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { IKeypoint } from "../../types/interface/keypoint.interface";

interface Props {
  isOpen: boolean;
  keypoint?: IKeypoint;
  onClose: () => void;
  onConfirm: () => Promise<void> | void; // parent will handle deletion + refresh
}

export default function KeypointConfirm({
  isOpen,
  keypoint,
  onClose,
  onConfirm,
}: Props) {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [loading, setLoading] = useState(false);
  if (!isOpen || !keypoint) return null;

  const handleDelete = async () => {
    setLoading(true);
    try {
      await Promise.resolve(onConfirm());
      onClose();
    } catch (err) {
      console.error("Delete failed", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
      <div className="bg-white rounded-lg shadow-lg w-full max-w-md relative p-6 text-center">
        <button
          onClick={onClose}
          className="absolute top-3 right-3 p-2 hover:bg-gray-100 rounded"
        >
          <XMarkIcon className="h-5 w-5 text-gray-600" />
        </button>

        <h3 className="text-lg font-semibold mb-3">Xoá keypoint</h3>
        <p className="text-sm text-gray-600 mb-6">
          Bạn có chắc muốn xoá “{keypoint.title[lang]}”
        </p>

        <div className="flex justify-center gap-3">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-200 rounded"
            disabled={loading}
          >
            Huỷ
          </button>
          <button
            onClick={handleDelete}
            className="px-4 py-2 bg-red-600 text-white rounded"
            disabled={loading}
          >
            {loading ? "Deleting..." : "Xoá"}
          </button>
        </div>
      </div>
    </div>
  );
}
