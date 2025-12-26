// src/components/courses/CourseConfirm.tsx
import React, { useState } from "react";
import { ICourse } from "../../types/interface/course.interface";
import { courseService } from "../../services/courseService";
import { useSelector } from "react-redux";
import { RootState } from "../../store";
import { motion, AnimatePresence } from "framer-motion";
import { getTranslationValue } from "../../utils/translation";

interface Props {
  isOpen: boolean;
  course?: ICourse;
  onClose: () => void;
  onConfirm: () => void; // parent will refresh state as needed
}

export default function CourseConfirm({
  isOpen,
  course,
  onClose,
  onConfirm,
}: Props) {
  const lang = useSelector((state: RootState) => state.lang.code);

  const [loading, setLoading] = useState(false);

  if (!isOpen || !course) return null;

  const handleDelete = async () => {
    setLoading(true);
    try {
      await courseService.remove(String(course._id));
      onConfirm();
      onClose();
    } catch (err) {
      console.error("Delete failed", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.2 }}
          className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6"
        >
          <div className="text-center">
            <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-red-600"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </div>

            <h3 className="text-lg font-medium text-gray-900 mb-2">
              Delete Course
            </h3>
            <p className="text-sm text-gray-500 mb-6">
              Are you sure you want to delete "
              <span className="font-medium">
                {getTranslationValue(course.title, lang) || "Unnamed Course"}
              </span>
              "? This action cannot be undone.
            </p>

            <div className="flex justify-center gap-3">
              <button
                onClick={onClose}
                disabled={loading}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-70"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                disabled={loading}
                className="px-4 py-2 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg hover:from-red-700 hover:to-red-800 transition-all flex items-center gap-2 disabled:opacity-70"
              >
                {loading ? (
                  <>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      className="h-4 w-4 animate-spin"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      ></circle>
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      ></path>
                    </svg>
                    <span>Deleting...</span>
                  </>
                ) : (
                  <span>Delete Course</span>
                )}
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
