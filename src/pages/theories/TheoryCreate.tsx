// Trong TheoryCreate.tsx
import React from "react";
import { useNavigate } from "react-router-dom";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import TheoryForm from "./TheoryForm";

export default function TheoryCreate() {
  const navigate = useNavigate();

  const handleSave = async (data: ILearningItem) => {
    try {
      navigate(`/theory/${data._id}`);
    } catch (error) {
      console.error("Error creating theory:", error);
      throw error;
    }
  };

  return (
    <div className="theory-create">
      <TheoryForm onSave={handleSave} />
    </div>
  );
}
