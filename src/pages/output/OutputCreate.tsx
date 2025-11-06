import React from "react";
import { useNavigate } from "react-router-dom";
import OutputForm from "./OutputForm";
import { ILesson } from "../../types/interface/lesson.interface";

export default function OutputCreate() {
  const navigate = useNavigate();

  const handleSave = (output: ILesson) => {
    navigate(`/output/${output._id}`);
  };

  return <OutputForm onSave={handleSave} />;
}
