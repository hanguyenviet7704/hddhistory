import React from "react";
import { useNavigate } from "react-router-dom";
import { ILearningItem } from "../../types/interface/learning-item/learning-item.interface";
import RoleplayForm from "./RoleplayForm";

export default function RoleplayCreate() {
  const navigate = useNavigate();

  const handleSave = async (data: ILearningItem) => {
    try {
      navigate(`/roleplay/${data._id}`);
    } catch (error) {
      console.error("Error creating roleplay:", error);
      throw error;
    }
  };

  const handleCancel = () => {
    navigate("/roleplays");
  };

  return (
    <div className="roleplay-create">
      <RoleplayForm onSave={handleSave} onCancel={handleCancel} />
    </div>
  );
}
