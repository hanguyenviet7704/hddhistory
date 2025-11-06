import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import ExerciseForm from "./ExerciseForm";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import { learningItemService } from "../../services/learningItemService";

export default function ExerciseDetail() {
  const { exerciseId } = useParams<{ exerciseId: string }>();
  const [exercise, setExercise] = useState<ILearningItem | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!exerciseId) return;

    setLoading(true);
    learningItemService
      .getById(exerciseId)
      .then((res) => {
        setExercise(res.data?.data ?? res.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [exerciseId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (!exercise) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-800 mb-2">
            Exercise not found
          </h2>
          <p className="text-gray-600">
            The exercise you're looking for doesn't exist.
          </p>
        </div>
      </div>
    );
  }

  return <ExerciseForm exercise={exercise} />;
}
