import React from "react";
import { render, screen } from "@testing-library/react";
import { Provider } from "react-redux";
import { LangCode } from "../../types/enum/common.enum";
import { store } from "../../store";
import KeypointModal, { buildKeypointPayload } from "./KeypointModal";

jest.mock("../files/CloudflareFileUpload", () => ({
  __esModule: true,
  default: () => <div data-testid="file-upload" />,
}));

jest.mock("../../services/voiceoverService", () => ({
  voiceoverService: {
    generateForKeypoint: jest.fn().mockResolvedValue({ data: {} }),
    generateForCourse: jest.fn().mockResolvedValue({ data: {} }),
  },
}));

describe("buildKeypointPayload", () => {
  // Audio is now owned entirely by the TTS voiceover flow, so saving a
  // keypoint must never emit an `audio` field (which would otherwise wipe or
  // overwrite generated audio).
  it("never includes audio, even when the keypoint already had audio", () => {
    const payload = buildKeypointPayload({
      title: { en: "Keypoint title" },
      description: { en: "Description" },
      estimateCompleTime: {},
      estimateCompleTimeInput: "",
      estimateCompleTimeUnit: "minute",
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

    expect((payload as Record<string, unknown>).audio).toBeUndefined();
    expect(payload.title).toEqual({ en: "Keypoint title" });
  });
});

describe("KeypointModal", () => {
  it("disables Generate voiceover when creating a new keypoint", () => {
    render(
      <Provider store={store}>
        <KeypointModal
          open
          onClose={jest.fn()}
          onSave={jest.fn()}
          keypoint={null}
        />
      </Provider>
    );

    const btn = screen.getByRole("button", { name: /generate voiceover/i });
    expect(btn).toBeDisabled();
  });

  it("enables Generate voiceover when editing an existing keypoint", () => {
    render(
      <Provider store={store}>
        <KeypointModal
          open
          onClose={jest.fn()}
          onSave={jest.fn()}
          keypoint={{
            _id: "keypoint-1",
            title: { en: "Keypoint title" },
            image: "https://example.com/image.png",
          }}
        />
      </Provider>
    );

    const btn = screen.getByRole("button", { name: /generate voiceover/i });
    expect(btn).toBeEnabled();
  });
});
