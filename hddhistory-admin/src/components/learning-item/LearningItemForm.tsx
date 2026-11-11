import React from "react";
import { LearningItemPayload } from "../../types/interface/learning-item/learning-item.interface";
import { LearningItemType } from "../../types/enum/learningItem.enum";
import { LangCode } from "../../types/enum/common.enum";
import {
  getCurrentTranslationValue,
  updateTranslationValue,
} from "../../utils/translation";

interface LearningItemFormProps {
  item: LearningItemPayload;
  onChange: (updatedItem: LearningItemPayload) => void;
  isTheory?: boolean;
}

const LearningItemForm: React.FC<LearningItemFormProps> = ({
  item,
  onChange,
  isTheory,
}) => {
  const handleInputChange = (field: keyof LearningItemPayload, value: any) => {
    onChange({
      ...item,
      [field]: value,
    });
  };

  const handleTagChange = (index: number, value: string) => {
    const newTags = [...item.tag];
    newTags[index] = value;
    handleInputChange("tag", newTags);
  };

  const addTag = () => {
    handleInputChange("tag", [...item.tag, ""]);
  };

  const removeTag = (index: number) => {
    const newTags = item.tag.filter((_, i) => i !== index);
    handleInputChange("tag", newTags);
  };

  return (
    <div className="learning-item-form bg-gray-50 p-6 rounded-lg mb-6">
      <h3 className="text-lg font-medium text-gray-900 mb-4">
        Basic Information
      </h3>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="form-group">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Keypoint ID
          </label>
          <input
            type="text"
            value={item.keypointId}
            onChange={(e) => handleInputChange("keypointId", e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
          />
        </div>

        <div className="form-group">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Title (EN)
          </label>
          <input
            type="text"
            value={getCurrentTranslationValue(item.title, LangCode.EN)}
            onChange={(e) =>
              handleInputChange(
                "title",
                updateTranslationValue(item.title, LangCode.EN, e.target.value),
              )
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
          />
        </div>

        <div className="form-group">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Image URL
          </label>
          <input
            type="text"
            value={item.image}
            onChange={(e) => handleInputChange("image", e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
          />
        </div>

        <div className="form-group">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Type
          </label>
          <select
            value={item.type}
            onChange={(e) =>
              handleInputChange("type", e.target.value as LearningItemType)
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
          >
            <option value={LearningItemType.THEORY}>Theory</option>
            <option value={LearningItemType.EXERCISE}>Exercise</option>
          </select>
        </div>

        <div className="form-group">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Index
          </label>
          <input
            type="number"
            value={item.index}
            onChange={(e) =>
              handleInputChange("index", parseInt(e.target.value))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-bronze-500"
          />
        </div>

        <div className="form-group">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={item.isSub}
              onChange={(e) => handleInputChange("isSub", e.target.checked)}
              className="h-4 w-4 text-bronze-600 focus:ring-bronze-500 border-gray-300 rounded"
            />
            <span className="ml-2 block text-sm text-gray-700">Is Sub</span>
          </label>
        </div>
      </div>

      <div className="mt-6">
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Tags
        </label>
        <div className="flex flex-wrap gap-2 mb-2">
          {item.tag.map((tag, index) => (
            <div
              key={index}
              className="flex items-center bg-bronze-100 rounded-md"
            >
              <input
                type="text"
                value={tag}
                onChange={(e) => handleTagChange(index, e.target.value)}
                className="px-3 py-1 bg-transparent border-0 focus:ring-0 text-sm"
                placeholder="Enter tag"
              />
              <button
                type="button"
                onClick={() => removeTag(index)}
                className="text-red-600 hover:text-red-800 px-2 py-1"
              >
                <svg
                  className="w-4 h-4"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  ></path>
                </svg>
              </button>
            </div>
          ))}
        </div>
        <button
          type="button"
          onClick={addTag}
          className="inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-bronze-500"
        >
          <svg
            className="w-4 h-4 mr-1"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M12 4v16m8-8H4"
            ></path>
          </svg>
          Add Tag
        </button>
      </div>
    </div>
  );
};

export default LearningItemForm;
