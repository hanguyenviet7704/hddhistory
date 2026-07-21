// Shared browser-only helpers for the JSON import/export affordances on admin
// list/config pages (e.g. StudyThemeList's bulk preset backup, OnboardingConfigPage's
// singleton config backup). Frontend-only — no new backend endpoints; pages
// keep using their existing entity service for the actual create/update calls.

/**
 * Serialize `data` as pretty-printed JSON and trigger a browser download.
 */
export function downloadJson(filename: string, data: unknown): void {
  const json = JSON.stringify(data, null, 2);
  const blob = new Blob([json], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

/**
 * Open a programmatic file picker restricted to JSON, read the chosen file,
 * and resolve the parsed value. Rejects if the user picks no file (best
 * effort — not every browser fires a cancel event) or the file isn't valid
 * JSON.
 */
export function pickJsonFile(): Promise<any> {
  return new Promise((resolve, reject) => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "application/json,.json";
    input.style.display = "none";

    let settled = false;
    const cleanup = () => {
      input.remove();
    };

    input.onchange = () => {
      const file = input.files?.[0];
      cleanup();
      if (!file) {
        settled = true;
        reject(new Error("No file selected"));
        return;
      }
      const reader = new FileReader();
      reader.onload = () => {
        settled = true;
        try {
          resolve(JSON.parse(String(reader.result)));
        } catch {
          reject(new Error("Selected file is not valid JSON"));
        }
      };
      reader.onerror = () => {
        settled = true;
        reject(new Error("Failed to read the selected file"));
      };
      reader.readAsText(file);
    };

    // Supported in modern Chromium/Firefox — lets a cancelled picker reject
    // promptly instead of leaving the caller hanging forever.
    (input as any).oncancel = () => {
      if (settled) return;
      settled = true;
      cleanup();
      reject(new Error("No file selected"));
    };

    document.body.appendChild(input);
    input.click();
  });
}

// Fields Mongo/the API attach automatically (see meup-api base schema) that
// must never round-trip back through create/update payloads.
const SERVER_MANAGED_KEYS = [
  "_id",
  "createdBy",
  "updatedBy",
  "createdAt",
  "updatedAt",
  "__v",
] as const;

/**
 * Shallow-clone `obj` with server-managed bookkeeping fields removed, so an
 * exported record can be re-imported (created/updated) without the backend
 * rejecting or ignoring stray fields.
 */
export function stripServerFields<T extends Record<string, any>>(
  obj: T
): Omit<T, (typeof SERVER_MANAGED_KEYS)[number]> {
  const clone: Record<string, any> = { ...obj };
  for (const key of SERVER_MANAGED_KEYS) {
    delete clone[key];
  }
  return clone as Omit<T, (typeof SERVER_MANAGED_KEYS)[number]>;
}
