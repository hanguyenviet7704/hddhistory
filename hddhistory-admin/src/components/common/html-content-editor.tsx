import React, { useEffect, useState } from "react";
import { EditorContent, useEditor } from "@tiptap/react";
import StarterKit from "@tiptap/starter-kit";
import Underline from "@tiptap/extension-underline";
import TextStyle from "@tiptap/extension-text-style";
import Color from "@tiptap/extension-color";
import { Extension } from "@tiptap/core";

const FontSize = Extension.create({
  name: "fontSize",
  addGlobalAttributes() {
    return [
      {
        types: ["textStyle"],
        attributes: {
          fontSize: {
            default: null,
            parseHTML: (element) => element.style.fontSize || null,
            renderHTML: (attributes) => {
              if (!attributes.fontSize) return {};
              return { style: `font-size: ${attributes.fontSize}` };
            },
          },
        },
      },
    ];
  },
  addCommands() {
    return {
      setFontSize:
        (size: string) =>
        ({ chain }: { chain: any }) =>
          chain().setMark("textStyle", { fontSize: size }).run(),
      unsetFontSize:
        () =>
        ({ chain }: { chain: any }) =>
          chain().setMark("textStyle", { fontSize: null }).run(),
    } as any;
  },
});

interface HtmlContentEditorProps {
  value: string;
  onChange: (html: string) => void;
  minHeight?: number;
}

export default function HtmlContentEditor({
  value,
  onChange,
  minHeight = 200,
}: HtmlContentEditorProps) {
  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [2, 3, 4] },
      }),
      Underline,
      TextStyle,
      Color.configure({ types: ["textStyle"] }),
      FontSize,
    ],
    content: value || "",
    editorProps: {
      attributes: {
        style: `min-height: ${minHeight}px; padding: 12px; border: 1px solid #d0d7de; border-radius: 8px; background: white; outline: none;`,
      },
    },
    onUpdate: ({ editor: nextEditor }) => {
      onChange(nextEditor.getHTML());
    },
  });

  const [currentFontSize, setCurrentFontSize] = useState("");

  useEffect(() => {
    if (!editor) return;
    const current = editor.getHTML();
    if (current !== (value || "")) {
      editor.commands.setContent(value || "", false);
    }
  }, [editor, value]);

  useEffect(() => {
    if (!editor) return;
    const syncFontSize = () => {
      const size = editor.getAttributes("textStyle").fontSize || "";
      setCurrentFontSize(size);
    };
    editor.on("selectionUpdate", syncFontSize);
    editor.on("transaction", syncFontSize);
    syncFontSize();
    return () => {
      editor.off("selectionUpdate", syncFontSize);
      editor.off("transaction", syncFontSize);
    };
  }, [editor]);

  if (!editor) return null;

  const toolbarButtonClass =
    "px-3 py-1.5 rounded-md text-sm border border-gray-200 bg-white hover:bg-gray-50";

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-2 rounded-lg border border-gray-200 bg-gray-50 p-2">
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleBold().run()}
        >
          Bold
        </button>
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleItalic().run()}
        >
          Italic
        </button>
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleUnderline().run()}
        >
          Underline
        </button>
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleBulletList().run()}
        >
          Bullet
        </button>
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleOrderedList().run()}
        >
          Number
        </button>
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
        >
          H2
        </button>
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
        >
          H3
        </button>
        <select
          className="rounded-md border border-gray-200 bg-white px-2 py-1.5 text-sm"
          value={currentFontSize}
          onChange={(event) => {
            const next = event.target.value;
            if (!next) {
              (editor.chain().focus() as any).unsetFontSize().run();
              return;
            }
            (editor.chain().focus() as any).setFontSize(next).run();
          }}
        >
          <option value="">Font size</option>
          <option value="12px">12px</option>
          <option value="14px">14px</option>
          <option value="16px">16px</option>
          <option value="18px">18px</option>
          <option value="24px">24px</option>
          <option value="32px">32px</option>
        </select>
        <input
          type="color"
          className="h-9 w-12 rounded border border-gray-200 bg-white p-1"
          onChange={(event) =>
            editor.chain().focus().setColor(event.target.value).run()
          }
          title="Text color"
        />
        <button
          type="button"
          className={toolbarButtonClass}
          onClick={() => editor.chain().focus().unsetAllMarks().clearNodes().run()}
        >
          Clear
        </button>
      </div>

      <EditorContent editor={editor} />
    </div>
  );
}
