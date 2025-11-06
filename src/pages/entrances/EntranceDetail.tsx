import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import EntranceForm from "./EntranceForm";
import { ILesson } from "../../types/interface/lesson.interface";
import { lessonService } from "../../services/lessonService";

export default function EntranceDetail() {
  const { lessonId } = useParams<{ lessonId: string }>();
  const [entrance, setEntrance] = useState<ILesson | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!lessonId) return;

    setLoading(true);
    lessonService
      .getById(lessonId)
      .then((res) => {
        setEntrance(res.data?.data ?? res.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [lessonId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (!entrance) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-2">
            Entrance not found
          </h2>
          <p className="text-gray-600">
            The entrance you're looking for doesn't exist.
          </p>
        </div>
      </div>
    );
  }

  return <EntranceForm entrance={entrance} />;
}
