import React from "react";
import { useNavigate } from "react-router-dom";
import LessonForm from "./LessonForm";
import { ILesson } from "../../types/interface/lesson.interface";

export default function LessonCreate() {
  const navigate = useNavigate();

  const handleSave = (lesson: ILesson) => {
    navigate(`/lesson/${lesson._id}`);
  };

  return <LessonForm onSave={handleSave} />;
}
