// src/pages/settings/SettingsPage.tsx
import { useState } from "react";
import {
  UserIcon,
  TagIcon,
  PhotoIcon,
  SparklesIcon,
  PaintBrushIcon,
} from "@heroicons/react/24/outline";
import UserManagement from "../../components/setting/UserManagement";
import TagManagement from "../../components/setting/TagManagement";
import AvatarManagement from "../../components/setting/AvatarManagement";
import IconManagement from "../../components/setting/IconManagement";
import RoleplayColorManagement from "../../components/setting/RoleplayColorManagement";

const SettingsPage = () => {
  const [activeTab, setActiveTab] = useState<
    "users" | "tags" | "avatars" | "icons" | "roleplayColors"
  >("tags");

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="max-w-6xl mx-auto">
        {/* Tab buttons */}
        <div className="flex flex-wrap space-x-2 mb-6">
          <button
            onClick={() => setActiveTab("users")}
            className={`
              flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors mb-2
              ${
                activeTab === "users"
                  ? "bg-blue-500 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }
            `}
          >
            <UserIcon className="h-4 w-4 mr-2" />
            Users
          </button>
          <button
            onClick={() => setActiveTab("tags")}
            className={`
              flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors mb-2
              ${
                activeTab === "tags"
                  ? "bg-green-500 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }
            `}
          >
            <TagIcon className="h-4 w-4 mr-2" />
            Tags
          </button>
          <button
            onClick={() => setActiveTab("avatars")}
            className={`
              flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors mb-2
              ${
                activeTab === "avatars"
                  ? "bg-blue-600 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }
            `}
          >
            <PhotoIcon className="h-4 w-4 mr-2" />
            Avatars
          </button>
          <button
            onClick={() => setActiveTab("icons")}
            className={`
              flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors mb-2
              ${
                activeTab === "icons"
                  ? "bg-purple-600 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }
            `}
          >
            <SparklesIcon className="h-4 w-4 mr-2" />
            Icons
          </button>
          <button
            onClick={() => setActiveTab("roleplayColors")}
            className={`
              flex items-center px-4 py-2 rounded-lg text-sm font-medium transition-colors mb-2
              ${
                activeTab === "roleplayColors"
                  ? "bg-indigo-600 text-white"
                  : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
              }
            `}
          >
            <PaintBrushIcon className="h-4 w-4 mr-2" />
            Roleplay Colors
          </button>
        </div>

        {/* Content based on active tab */}
        {activeTab === "users" && <UserManagement />}
        {activeTab === "tags" && <TagManagement />}
        {activeTab === "avatars" && <AvatarManagement />}
        {activeTab === "icons" && <IconManagement />}
        {activeTab === "roleplayColors" && <RoleplayColorManagement />}
      </div>
    </div>
  );
};

export default SettingsPage;
