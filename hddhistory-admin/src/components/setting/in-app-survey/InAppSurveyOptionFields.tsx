import {
  closestCenter,
  DndContext,
  DragEndEvent,
  PointerSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  SortableContext,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { Bars3Icon } from "@heroicons/react/24/outline";
import { LangCode } from "../../../types/enum/common.enum";
import {
  InAppSurveyClosedQuestionType,
  InAppSurveyOptionPayload,
} from "../../../types/interface/in-app-survey.interface";
import { updateTranslationValue } from "../../../utils/translation";
import CloudflareFileUpload from "../../files/CloudflareFileUpload";

interface Props {
  lang: LangCode;
  options: InAppSurveyOptionPayload[];
  selectionType: InAppSurveyClosedQuestionType;
  onAdd: () => void;
  onChange: (
    optionIndex: number,
    nextOption: Partial<InAppSurveyOptionPayload>
  ) => void;
  onReorder: (oldIndex: number, newIndex: number) => void;
  onSelectionTypeChange: (type: InAppSurveyClosedQuestionType) => void;
  onRemove: (optionIndex: number) => void;
}

const getOptionSortableId = (
  option: InAppSurveyOptionPayload,
  optionIndex: number
) => option.id || `option-${optionIndex}`;

interface OptionRowProps {
  lang: LangCode;
  option: InAppSurveyOptionPayload;
  optionIndex: number;
  optionsCount: number;
  onChange: Props["onChange"];
  onRemove: Props["onRemove"];
}

const SortableOptionRow = ({
  lang,
  option,
  optionIndex,
  optionsCount,
  onChange,
  onRemove,
}: OptionRowProps) => {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } =
    useSortable({ id: getOptionSortableId(option, optionIndex) });

  return (
    <div
      ref={setNodeRef}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      className={`grid grid-cols-1 gap-4 rounded-xl border bg-slate-50/70 p-4 md:grid-cols-[auto_160px_1fr_auto] ${
        isDragging ? "border-bronze-300 shadow-md" : "border-slate-200"
      }`}
    >
      <button
        type="button"
        className="self-center rounded-lg border border-slate-200 bg-white p-2 text-slate-500 shadow-sm transition hover:bg-bronze-50 hover:text-bronze-600"
        {...attributes}
        {...listeners}
      >
        <Bars3Icon className="h-5 w-5" />
      </button>
      <CloudflareFileUpload
        initialUrl={option.icon}
        onUrlChange={(url) => onChange(optionIndex, { icon: url })}
        label="Option Icon"
        uploadPayload={{ prefix: "", folder: "in-app-survey/options" }}
      />
      <div>
        <label className="mb-1 block text-sm font-semibold text-slate-700">
          Option Label ({lang})
        </label>
        <input
          value={option.value?.[lang] || ""}
          onChange={(e) =>
            onChange(optionIndex, {
              value: updateTranslationValue(option.value, lang, e.target.value),
            })
          }
          className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
          required
        />
      </div>
      <button
        type="button"
        onClick={() => onRemove(optionIndex)}
        className="self-end rounded-lg bg-red-50 px-3 py-2 text-sm font-semibold text-red-600 transition hover:bg-red-100 disabled:opacity-50"
        disabled={optionsCount <= 1}
      >
        Remove
      </button>
    </div>
  );
};
const InAppSurveyOptionFields = ({
  lang,
  options,
  selectionType,
  onAdd,
  onChange,
  onReorder,
  onSelectionTypeChange,
  onRemove,
}: Props) => {
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } })
  );

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const oldIndex = options.findIndex(
      (option, index) => getOptionSortableId(option, index) === active.id
    );
    const newIndex = options.findIndex(
      (option, index) => getOptionSortableId(option, index) === over.id
    );
    if (oldIndex < 0 || newIndex < 0) return;
    onReorder(oldIndex, newIndex);
  };

  return (
    <div className="space-y-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-wrap items-center justify-end gap-3">
        <label className="text-sm font-semibold text-slate-700">
          Selection Type
        </label>
        <select
          value={selectionType}
          onChange={(event) =>
            onSelectionTypeChange(
              event.target.value as InAppSurveyClosedQuestionType
            )
          }
          className="min-w-[170px] rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 outline-none transition focus:border-bronze-400 focus:ring-2 focus:ring-bronze-100"
        >
          <option value={InAppSurveyClosedQuestionType.MULTIPLE_CHOICE}>
            Multiple choice
          </option>
          <option value={InAppSurveyClosedQuestionType.SINGLE_CHOICE}>
            Single choice
          </option>
        </select>
      </div>

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={options.map(getOptionSortableId)}
          strategy={verticalListSortingStrategy}
        >
          <div className="space-y-3">
            {options.map((option, optionIndex) => (
              <SortableOptionRow
                key={getOptionSortableId(option, optionIndex)}
                lang={lang}
                option={option}
                optionIndex={optionIndex}
                optionsCount={options.length}
                onChange={onChange}
                onRemove={onRemove}
              />
            ))}
          </div>
        </SortableContext>
      </DndContext>

      <div className="flex justify-center pt-2">
        <button
          type="button"
          onClick={onAdd}
          className="rounded-full bg-bronze-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-bronze-700"
        >
          Add Option
        </button>
      </div>
    </div>
  );
};

export default InAppSurveyOptionFields;
