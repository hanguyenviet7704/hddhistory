// Read/write the .xlsx interchange files for the habit + reanchor
// export/import feature. Column layouts mirror the "Build Habit" Google Sheet so
// content editors can round-trip through Google Sheets. Import forward-fills
// blank "Course Title" / "Keypoint #" cells (merged-cell continuation rows).
import * as XLSX from "xlsx";

const LANGS = ["vi", "en", "zh", "ja", "ko"] as const;
type Lang = (typeof LANGS)[number];
type MultiLang = Partial<Record<Lang, string>>;

export interface ReanchorRow {
  course: string;
  index: number;
  reason: MultiLang;
}

export interface HabitRow {
  course: string;
  section: number;
  keypoint: number;
  habitIndex: number;
  keypointTitleVi?: string;
  title: MultiLang;
}

const str = (v: unknown): string => (v == null ? "" : String(v)).trim();

const pickLangs = (row: Record<string, string>): MultiLang => {
  const out: MultiLang = {};
  for (const l of LANGS) {
    const v = str(row[l]);
    if (v) out[l] = v;
  }
  return out;
};

function triggerDownload(wb: XLSX.WorkBook, filename: string) {
  const out = XLSX.write(wb, { bookType: "xlsx", type: "array" });
  const blob = new Blob([out], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

// Read the first worksheet as an array-of-arrays, locate the header row (the one
// containing "Course Title"), and return { header labels lowercased -> col idx,
// data rows }.
function readSheet(data: ArrayBuffer): { colOf: (name: string) => number; rows: string[][] } {
  const wb = XLSX.read(data, { type: "array" });
  const ws = wb.Sheets[wb.SheetNames[0]];
  const aoa = XLSX.utils.sheet_to_json<string[]>(ws, { header: 1, defval: "", blankrows: false });
  let headerIdx = aoa.findIndex((r) => r.some((c) => str(c).toLowerCase() === "course title"));
  if (headerIdx < 0) headerIdx = 0;
  const header = (aoa[headerIdx] || []).map((c) => str(c).toLowerCase());
  const colOf = (name: string) => header.indexOf(name.toLowerCase());
  return { colOf, rows: aoa.slice(headerIdx + 1) as string[][] };
}

// ---------- Re-anchor ----------

export function downloadReanchorXlsx(rows: ReanchorRow[]) {
  const sorted = [...rows].sort(
    (a, b) => a.course.localeCompare(b.course) || a.index - b.index,
  );
  const header = ["Course Title", "#", "VI", "EN", "ZH", "JA", "KO"];
  const aoa: (string | number)[][] = [header];
  let prevCourse = "";
  for (const r of sorted) {
    aoa.push([
      r.course === prevCourse ? "" : r.course, // merged-cell style: blank on repeat
      r.index,
      r.reason.vi ?? "",
      r.reason.en ?? "",
      r.reason.zh ?? "",
      r.reason.ja ?? "",
      r.reason.ko ?? "",
    ]);
    prevCourse = r.course;
  }
  const ws = XLSX.utils.aoa_to_sheet(aoa);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "Re-anchor");
  triggerDownload(wb, "reanchor-reasons.xlsx");
}

export async function parseReanchorXlsx(file: File): Promise<ReanchorRow[]> {
  const { colOf, rows } = readSheet(await file.arrayBuffer());
  const cCourse = colOf("course title");
  const cIndex = colOf("#");
  const langCol: Record<Lang, number> = {
    vi: colOf("vi"),
    en: colOf("en"),
    zh: colOf("zh"),
    ja: colOf("ja"),
    ko: colOf("ko"),
  };
  const out: ReanchorRow[] = [];
  let course = "";
  for (const raw of rows) {
    const c = cCourse >= 0 ? str(raw[cCourse]) : "";
    if (c) course = c;
    const idx = cIndex >= 0 ? parseInt(str(raw[cIndex]), 10) : NaN;
    if (!course || !Number.isFinite(idx)) continue;
    const reason = pickLangs({
      vi: str(raw[langCol.vi]),
      en: str(raw[langCol.en]),
      zh: str(raw[langCol.zh]),
      ja: str(raw[langCol.ja]),
      ko: str(raw[langCol.ko]),
    });
    if (!Object.keys(reason).length) continue;
    out.push({ course, index: idx, reason });
  }
  return out;
}

// ---------- Habit ----------

export function downloadHabitXlsx(rows: HabitRow[]) {
  const sorted = [...rows].sort(
    (a, b) =>
      a.course.localeCompare(b.course) ||
      a.section - b.section ||
      a.keypoint - b.keypoint ||
      a.habitIndex - b.habitIndex,
  );
  const header = [
    "Course Title",
    "Keypoint #",
    "Keypoint title (VI)",
    "Habit #",
    "VI",
    "EN",
    "ZH",
    "JA",
    "KO",
  ];
  const aoa: (string | number)[][] = [header];
  let prevCourse = "";
  let prevKp = "";
  for (const r of sorted) {
    const kp = `S${r.section}-KP${r.keypoint}`;
    aoa.push([
      r.course === prevCourse ? "" : r.course,
      kp === prevKp && r.course === prevCourse ? "" : kp,
      r.keypointTitleVi ?? "",
      r.habitIndex,
      r.title.vi ?? "",
      r.title.en ?? "",
      r.title.zh ?? "",
      r.title.ja ?? "",
      r.title.ko ?? "",
    ]);
    prevCourse = r.course;
    prevKp = kp;
  }
  const ws = XLSX.utils.aoa_to_sheet(aoa);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "Habit");
  triggerDownload(wb, "habits.xlsx");
}

export async function parseHabitXlsx(file: File): Promise<HabitRow[]> {
  const { colOf, rows } = readSheet(await file.arrayBuffer());
  const cCourse = colOf("course title");
  const cKp = colOf("keypoint #");
  const cHabit = colOf("habit #");
  const langCol: Record<Lang, number> = {
    vi: colOf("vi"),
    en: colOf("en"),
    zh: colOf("zh"),
    ja: colOf("ja"),
    ko: colOf("ko"),
  };
  const out: HabitRow[] = [];
  let course = "";
  let kpRef = "";
  for (const raw of rows) {
    const c = cCourse >= 0 ? str(raw[cCourse]) : "";
    if (c) course = c;
    const kpCell = cKp >= 0 ? str(raw[cKp]) : "";
    if (kpCell) kpRef = kpCell;
    const habitIndex = cHabit >= 0 ? parseInt(str(raw[cHabit]), 10) : NaN;
    const m = /S(\d+)\s*-\s*KP(\d+)/i.exec(kpRef);
    if (!course || !m || !Number.isFinite(habitIndex)) continue;
    const title = pickLangs({
      vi: str(raw[langCol.vi]),
      en: str(raw[langCol.en]),
      zh: str(raw[langCol.zh]),
      ja: str(raw[langCol.ja]),
      ko: str(raw[langCol.ko]),
    });
    if (!Object.keys(title).length) continue;
    out.push({
      course,
      section: parseInt(m[1], 10),
      keypoint: parseInt(m[2], 10),
      habitIndex,
      title,
    });
  }
  return out;
}
