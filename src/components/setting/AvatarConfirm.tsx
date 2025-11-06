// src/components/setting/AvatarConfirm.tsx
import { Dialog } from "@headlessui/react";
import { IAvatar } from "../../types/interface/avatar.interface";

interface AvatarConfirmProps {
  isOpen: boolean;
  avatar?: IAvatar;
  onClose: () => void;
  onConfirm: () => void;
}

const AvatarConfirm = ({
  isOpen,
  avatar,
  onClose,
  onConfirm,
}: AvatarConfirmProps) => {
  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-sm rounded-lg bg-white p-6 shadow-xl">
          <Dialog.Title className="text-lg font-medium text-gray-900 mb-2">
            Confirm Delete
          </Dialog.Title>
          <Dialog.Description className="text-sm text-gray-500 mb-4">
            Are you sure you want to delete this avatar? This action cannot be
            undone.
          </Dialog.Description>
          {avatar && (
            <div className="mb-4 flex justify-center">
              <div className="h-16 w-16">
                {avatar.url ? (
                  <img
                    src={avatar.url}
                    alt="Avatar to delete"
                    className="h-full w-full object-cover rounded-full"
                  />
                ) : null}
              </div>
            </div>
          )}
          <div className="flex justify-end space-x-2">
            <button
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors"
            >
              Delete
            </button>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
};

export default AvatarConfirm;
