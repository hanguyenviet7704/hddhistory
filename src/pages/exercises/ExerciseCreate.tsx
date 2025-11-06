import React from "react";
import { useNavigate } from "react-router-dom";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import ExerciseForm from "./ExerciseForm";

export default function ExerciseCreate() {
  const navigate = useNavigate();

  const handleSave = async (data: ILearningItem) => {
    try {
      navigate(`/exercise/${data._id}`);
    } catch (error) {
      console.error("Error creating exercise:", error);
      throw error;
    }
  };

  const handleCancel = () => {
    navigate("/exercises");
  };

  return (
    <div className="exercise-create">
      <ExerciseForm onSave={handleSave} onCancel={handleCancel} />
    </div>
  );
}
