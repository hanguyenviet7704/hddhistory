import React from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { LangCode } from "../../types/enum/common.enum";
import { store } from "../../store";
import KeypointModal, { buildKeypointPayload } from "./KeypointModal";

jest.mock("../files/CloudflareFileUpload", () => ({
  __esModule: true,
  default: ({
    onUrlChange,
    accept,
  }: {
    onUrlChange: (value: string) => void;
    accept?: string;
  }) => (
    <button
      type="button"
      data-testid={accept === "audio/*" ? "clear-audio-upload" : "clear-upload"}
      onClick={() => onUrlChange("")}
    >
      clear upload
    </button>
  ),
}));

describe("buildKeypointPayload", () => {
  it("sends an explicit empty audio object when editing and audio was cleared", () => {
    const payload = buildKeypointPayload({
      title: { en: "Keypoint title" },
      description: { en: "Description" },
      estimateCompleTime: {},
      estimateCompleTimeInput: "",
      estimateCompleTimeUnit: "minute",
      audio: {
        url: { en: "" },
        text: { en: "" },
      },
      image: "https://example.com/image.png",
      tag: [],
      lang: LangCode.EN,
      keypoint: {
        _id: "keypoint-1",
        title: { en: "Keypoint title" },
        description: { en: "Description" },
        image: "https://example.com/image.png",
        audio: {
          url: { en: "https://example.com/audio.mp3" },
          text: { en: "Transcript" },
        },
      },
    });

    expect(payload.audio).toEqual({});
  });

  it("keeps audio omitted when creating a keypoint without audio", () => {
    const payload = buildKeypointPayload({
      title: { en: "New keypoint" },
      description: {},
      estimateCompleTime: {},
      estimateCompleTimeInput: "",
      estimateCompleTimeUnit: "minute",
      audio: {},
      image: "https://example.com/image.png",
      tag: [],
      lang: LangCode.EN,
      keypoint: null,
    });

    expect(payload.audio).toBeUndefined();
  });

  it("keeps remaining audio content instead of clearing the whole field", () => {
    const payload = buildKeypointPayload({
      title: { en: "Keypoint title" },
      description: { en: "Description" },
      estimateCompleTime: {},
      estimateCompleTimeInput: "",
      estimateCompleTimeUnit: "minute",
      audio: {
        url: { en: "" },
        text: { en: "Transcript kept" },
      },
      image: "https://example.com/image.png",
      tag: [],
      lang: LangCode.EN,
      keypoint: {
        _id: "keypoint-1",
        title: { en: "Keypoint title" },
        description: { en: "Description" },
        image: "https://example.com/image.png",
        audio: {
          url: { en: "https://example.com/audio.mp3" },
          text: { en: "Transcript" },
        },
      },
    });

    expect(payload.audio).toEqual({
      text: { en: "Transcript kept" },
    });
  });
});

describe("KeypointModal", () => {
  it("submits an explicit empty audio object after clearing existing audio", async () => {
    const onSave = jest.fn().mockResolvedValue(undefined);

    render(
      <Provider store={store}>
        <KeypointModal
          open
          onClose={jest.fn()}
          onSave={onSave}
          keypoint={{
            _id: "keypoint-1",
            title: { en: "Keypoint title" },
            description: { en: "Description" },
            image: "https://example.com/image.png",
            audio: {
              url: { en: "https://example.com/audio.mp3" },
              text: { en: "Transcript" },
            },
          }}
        />
      </Provider>
    );

    fireEvent.click(screen.getByTestId("clear-audio-upload"));
    fireEvent.change(screen.getByPlaceholderText("Enter transcript or audio text"), {
      target: { value: "" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => {
      expect(onSave).toHaveBeenCalledWith(
        expect.objectContaining({
          audio: {},
        })
      );
    });
  });
});
