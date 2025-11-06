// src/components/setting/IconConfirm.tsx
import { Dialog } from "@headlessui/react";
import { IIcon } from "../../types/interface/icon.interface";

interface IconConfirmProps {
  isOpen: boolean;
  icon?: IIcon;
  onClose: () => void;
  onConfirm: () => void;
}

const IconConfirm = ({
  isOpen,
  icon,
  onClose,
  onConfirm,
}: IconConfirmProps) => {
  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-sm rounded-lg bg-white p-6 shadow-xl">
          <Dialog.Title className="text-lg font-medium text-gray-900 mb-2">
            Confirm Delete
          </Dialog.Title>
          <Dialog.Description className="text-sm text-gray-500 mb-4">
            Are you sure you want to delete this icon? This action cannot be
            undone.
          </Dialog.Description>
          {icon && (
            <div className="mb-4 flex justify-center">
              <div className="h-12 w-12">
                {icon.url ? (
                  <img
                    src={icon.url}
                    alt="Icon to delete"
                    className="h-full w-full object-cover"
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

export default IconConfirm;
