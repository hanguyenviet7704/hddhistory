import { Dialog } from "@headlessui/react";
import {
  IColorStyle,
  IRoleplayColorTemplate,
} from "../../types/interface/learning-item/roleplays/color-template.interface";

interface RoleplayColorConfirmProps {
  isOpen: boolean;
  template?: IRoleplayColorTemplate;
  onClose: () => void;
  onConfirm: () => void;
}

const ColorSwatch = ({
  label,
  value,
}: {
  label: string;
  value?: IColorStyle;
}) => {
  if (!value) return null;
  return (
    <div className="rounded-lg border overflow-hidden">
      <div className="text-xs font-medium text-gray-500 px-2 py-1 bg-gray-50">
        {label}
      </div>
      <div
        className="p-3 text-sm font-semibold"
        style={{
          backgroundColor: value.backgroundColor || "#ffffff",
          color: value.textColor || "#111827",
        }}
      >
        Preview
      </div>
      <div className="text-[11px] text-gray-500 px-2 py-1 border-t">
        BG: {value.backgroundColor || "--"}
        <br />
        Text: {value.textColor || "--"}
      </div>
    </div>
  );
};

const RoleplayColorConfirm = ({
  isOpen,
  template,
  onClose,
  onConfirm,
}: RoleplayColorConfirmProps) => {
  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/30" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-lg rounded-lg bg-white p-6 shadow-xl">
          <Dialog.Title className="text-lg font-medium text-gray-900 mb-2">
            Confirm Delete
          </Dialog.Title>
          <Dialog.Description className="text-sm text-gray-500 mb-4">
            Are you sure you want to delete this roleplay color template? This
            action cannot be undone.
          </Dialog.Description>

          {template && (
            <div className="space-y-3 mb-4">
              <div className="font-semibold">{template.title}</div>
              <div className="grid grid-cols-2 gap-3">
                <ColorSwatch
                  label="Conversation Left"
                  value={template.conversation?.left}
                />
                <ColorSwatch
                  label="Conversation Right"
                  value={template.conversation?.right}
                />
                <ColorSwatch label="Leading Text" value={template.leadingText} />
                <ColorSwatch label="Hint" value={template.hint} />
                <ColorSwatch label="Transition" value={template.transition} />
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

export default RoleplayColorConfirm;
