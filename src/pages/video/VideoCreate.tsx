import React from "react";
import { useNavigate } from "react-router-dom";
import { ILesson } from "../../types/interface/lesson.interface";
import VideoForm from "./VideoForm";

export default function VideoCreate() {
  const navigate = useNavigate();

  const handleSave = (videoLesson: ILesson) => {
    navigate(`/video/${videoLesson._id}`);
  };

  return <VideoForm onSave={handleSave} />;
}
