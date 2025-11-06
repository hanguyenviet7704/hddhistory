// src/pages/settings/UserManagement.tsx
import { UserIcon } from "@heroicons/react/24/outline";

const UserManagement = () => {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
      <div className="text-center">
        <UserIcon className="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h2 className="text-xl font-medium text-gray-900 mb-2">
          User Management
        </h2>
        <p className="text-gray-500 mb-6">
          User management functionality will be available soon.
        </p>
        <div className="text-sm text-gray-400">
          This section will allow you to manage user accounts, permissions, and
          roles.
        </div>
      </div>
    </div>
  );
};

export default UserManagement;
