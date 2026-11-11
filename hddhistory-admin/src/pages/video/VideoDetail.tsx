import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { ILesson } from "../../types/interface/lesson.interface";
import { lessonService } from "../../services/lessonService";
import VideoForm from "./VideoForm";

export default function VideoDetail() {
  const { videoId } = useParams<{ videoId: string }>();
  const [videoLesson, setVideoLesson] = useState<ILesson | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!videoId) return;
    setLoading(true);
    lessonService
      .getById(videoId)
      .then((response) => {
        setVideoLesson(response.data?.data ?? response.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [videoId]);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 p-6">
        <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-t-2 border-brand-500"></div>
      </div>
    );
  }

  if (!videoLesson) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 p-6">
        <div className="text-center">
          <h2 className="mb-2 text-2xl font-bold text-gray-800">
            Video not found
          </h2>
          <p className="text-gray-600">
            The video lesson you&apos;re looking for doesn&apos;t exist.
          </p>
        </div>
      </div>
    );
  }

  return <VideoForm videoLesson={videoLesson} />;
}
