import React, { useState } from "react";
import { BookOpenIcon } from "@heroicons/react/24/outline";
import CourseStatistics from "./components/CourseStatistics";

type TabKey = "course";

const StatisticsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabKey>("course");

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-7xl mx-auto">
        <div className="flex flex-wrap space-x-2 mb-6">
          <button
            onClick={() => setActiveTab("course")}
            className={`
              flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors mb-2
              ${
                activeTab === "course"
                  ? "bg-blue-500 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }
            `}
          >
            <BookOpenIcon className="h-4 w-4 mr-2" />
            Course
          </button>
        </div>

        {activeTab === "course" && <CourseStatistics />}
      </div>
    </div>
  );
};

export default StatisticsPage;
