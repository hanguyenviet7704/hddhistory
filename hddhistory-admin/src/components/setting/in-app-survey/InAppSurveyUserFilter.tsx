import { XMarkIcon } from "@heroicons/react/24/outline";
import { useEffect, useState } from "react";
import { userService } from "../../../services/userService";
import { IUser, UserListQuery } from "../../../types/interface/user.interface";

interface Props {
  selectedUserId: string;
  onChange: (userId: string) => void;
}

const getUserId = (user: Partial<IUser>) =>
  (user as any)._id || (user as any).id || "";

const getUserLabel = (user: Partial<IUser>) =>
  [user.name, user.email].filter(Boolean).join(" - ") || getUserId(user);

const normalizeUsers = (payload: any): IUser[] => {
  const data = payload?.data?.data ?? payload?.data ?? payload ?? {};
  const list = data.items ?? data.list ?? data.users ?? data.data ?? data;
  return Array.isArray(list) ? list : [];
};

const InAppSurveyUserFilter = ({ selectedUserId, onChange }: Props) => {
  const [keyword, setKeyword] = useState("");
  const [users, setUsers] = useState<IUser[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const handle = setTimeout(() => {
      const search = keyword.trim();
      if (!search) {
        setUsers([]);
        return;
      }
      setLoading(true);
      userService
        .getList(new UserListQuery({ search, take: 8 }))
        .then((res) => setUsers(normalizeUsers(res)))
        .catch((error) => {
          console.error("Failed to fetch users for survey filter", error);
          setUsers([]);
        })
        .finally(() => setLoading(false));
    }, 300);
    return () => clearTimeout(handle);
  }, [keyword]);

  return (
    <div className="relative max-w-md">
      <label className="mb-1 block text-sm font-semibold text-slate-700">
        Search user
      </label>
      <div className="relative">
        <input
          value={keyword}
          onChange={(event) => setKeyword(event.target.value)}
          placeholder="Search by name or email"
          className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 pr-9 text-sm text-slate-950 outline-none transition focus:border-bronze-400 focus:ring-2 focus:ring-bronze-100"
        />
        {keyword || selectedUserId ? (
          <button
            type="button"
            onClick={() => {
              onChange("");
              setKeyword("");
              setUsers([]);
            }}
            className="absolute right-2 top-1/2 rounded-full p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"
            aria-label="Clear user search"
          >
            <XMarkIcon className="h-4 w-4" />
          </button>
        ) : null}
      </div>
      {selectedUserId ? (
        <button
          type="button"
          onClick={() => {
            onChange("");
            setKeyword("");
            setUsers([]);
          }}
          className="mt-2 text-xs font-semibold text-bronze-600"
        >
          Clear selected user: {selectedUserId}
        </button>
      ) : null}
      {keyword.trim() ? (
        <div className="absolute z-20 mt-2 max-h-64 w-full overflow-auto rounded-xl border border-slate-200 bg-white shadow-lg">
          {loading ? (
            <div className="px-3 py-2 text-sm text-slate-500">Searching...</div>
          ) : users.length ? (
            users.map((user) => {
              const userId = getUserId(user);
              return (
                <button
                  key={userId || user.email}
                  type="button"
                  onClick={() => {
                    if (!userId) return;
                    onChange(userId);
                    setKeyword(getUserLabel(user));
                    setUsers([]);
                  }}
                  className="block w-full px-3 py-2 text-left text-sm hover:bg-bronze-50"
                >
                  <div className="font-medium text-slate-900">
                    {user.name || user.email || userId}
                  </div>
                  <div className="text-xs text-slate-500">
                    {user.email || userId}
                  </div>
                </button>
              );
            })
          ) : (
            <div className="px-3 py-2 text-sm text-slate-500">
              No users found.
            </div>
          )}
        </div>
      ) : null}
    </div>
  );
};

export default InAppSurveyUserFilter;
