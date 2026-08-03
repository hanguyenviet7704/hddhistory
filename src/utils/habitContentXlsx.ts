// Read/write the .xlsx interchange files for the habit + reanchor
// export/import feature. Column layouts mirror the "Build Habit" Google Sheet so
// content editors can round-trip through Google Sheets. Import forward-fills
// blank "Course Title" / "Keypoint #" cells (merged-cell continuation rows).
import * as XLSX from "xlsx";

const LANGS = ["vi", "en", "zh", "ja", "ko"] as const;
type Lang = (typeof LANGS)[number];
type MultiLang = Partial<Record<Lang, string>>;

export interface ReanchorRow {
  // Existing doc _id, round-tripped through the sheet so import can update the
  // exact same record (preserving its id). Blank/absent for brand-new rows.
  id?: string;
  course: string;
  index: number;
  reason: MultiLang;
}

export interface HabitRow {
  id?: string;
  course: string;
  section: number;
  keypoint: number;
  habitIndex: number;
  keypointTitleVi?: string;
  title: MultiLang;
}

/** A sheet row the parser refused, with the spreadsheet row number to fix. */
export interface SkippedRow {
  /** 1-based, matching the row number shown in Excel / Google Sheets. */
  row: number;
  reason: string;
}

/**
 * Parsed rows plus what was thrown away getting there.
 *
 * The skipped list is not a nicety: rows dropped here never reach the server,
 * so they appear in NO count in the import report — not created, not updated,
 * not even "missing course". Without this the file can lose half its rows and
 * every number on screen still looks healthy.
 */
export interface ParseResult<T> {
  rows: T[];
  skipped: SkippedRow[];
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
function readSheet(data: ArrayBuffer): {
  colOf: (name: string) => number;
  header: string[];
  rows: string[][];
  /** Spreadsheet row number (1-based) of rows[i]. */
  rowNumber: (i: number) => number;
  sheetName: string;
} {
  const wb = XLSX.read(data, { type: "array" });
  const sheetName = wb.SheetNames[0];
  const ws = wb.Sheets[sheetName];
  // blankrows: true so an index still maps to the row number the editor sees.
  // A "row 412 was skipped" report that points at the wrong line is worse than
  // no report; blank rows are dropped in the loop instead, silently.
  const aoa = XLSX.utils.sheet_to_json<string[]>(ws, { header: 1, defval: "", blankrows: true });
  let headerIdx = aoa.findIndex((r) => r.some((c) => str(c).toLowerCase() === "course title"));
  if (headerIdx < 0) headerIdx = 0;
  const header = (aoa[headerIdx] || []).map((c) => str(c).toLowerCase());
  const colOf = (name: string) => header.indexOf(name.toLowerCase());
  return {
    colOf,
    header,
    rows: aoa.slice(headerIdx + 1) as string[][],
    rowNumber: (i: number) => headerIdx + 2 + i,
    sheetName,
  };
}

const isBlankRow = (raw: string[]) => !raw || raw.every((c) => !str(c));

/**
 * A missing column empties every row that depends on it, so the whole file
 * imports as "no valid rows" with nothing saying why. Fail loudly instead,
 * naming the worksheet that was read — only the FIRST one is, which is easy to
 * get wrong when the workbook has one tab per data type.
 */
function requireColumns(
  sheetName: string,
  header: string[],
  cols: Record<string, number>,
) {
  const missing = Object.entries(cols)
    .filter(([, idx]) => idx < 0)
    .map(([name]) => name);
  if (!missing.length) return;
  throw new Error(
    `Sheet "${sheetName}" is missing column(s): ${missing.join(", ")}. ` +
      `Found: ${header.filter(Boolean).join(", ") || "(no header row)"}. ` +
      `Only the first worksheet of the file is read.`,
  );
}

// ---------- Re-anchor ----------

export function downloadReanchorXlsx(rows: ReanchorRow[]) {
  const sorted = [...rows].sort(
    (a, b) => a.course.localeCompare(b.course) || a.index - b.index,
  );
  const header = ["ID", "Course Title", "#", "VI", "EN", "ZH", "JA", "KO"];
  const aoa: (string | number)[][] = [header];
  let prevCourse = "";
  for (const r of sorted) {
    aoa.push([
      r.id ?? "", // stable identity — do NOT edit this column
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

export async function parseReanchorXlsx(
  file: File,
): Promise<ParseResult<ReanchorRow>> {
  const { colOf, header, rows, rowNumber, sheetName } = readSheet(
    await file.arrayBuffer(),
  );
  const cId = colOf("id");
  const cCourse = colOf("course title");
  const cIndex = colOf("#");
  requireColumns(sheetName, header, {
    "Course Title": cCourse,
    "#": cIndex,
  });
  const langCol: Record<Lang, number> = {
    vi: colOf("vi"),
    en: colOf("en"),
    zh: colOf("zh"),
    ja: colOf("ja"),
    ko: colOf("ko"),
  };
  const out: ReanchorRow[] = [];
  const skipped: SkippedRow[] = [];
  let course = "";
  rows.forEach((raw, i) => {
    if (isBlankRow(raw)) return;
    const c = str(raw[cCourse]);
    if (c) course = c;
    const idx = parseInt(str(raw[cIndex]), 10);
    if (!course) {
      skipped.push({ row: rowNumber(i), reason: "no Course Title yet" });
      return;
    }
    if (!Number.isFinite(idx)) {
      skipped.push({
        row: rowNumber(i),
        reason: `# is not a number ("${str(raw[cIndex])}") — ${course}`,
      });
      return;
    }
    const reason = pickLangs({
      vi: str(raw[langCol.vi]),
      en: str(raw[langCol.en]),
      zh: str(raw[langCol.zh]),
      ja: str(raw[langCol.ja]),
      ko: str(raw[langCol.ko]),
    });
    if (!Object.keys(reason).length) {
      skipped.push({
        row: rowNumber(i),
        reason: `all language columns empty — ${course}`,
      });
      return;
    }
    const id = cId >= 0 ? str(raw[cId]) : "";
    out.push({ ...(id ? { id } : {}), course, index: idx, reason });
  });
  return { rows: out, skipped };
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
    "ID",
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
      r.id ?? "", // stable identity — do NOT edit this column
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

export async function parseHabitXlsx(
  file: File,
): Promise<ParseResult<HabitRow>> {
  const { colOf, header, rows, rowNumber, sheetName } = readSheet(
    await file.arrayBuffer(),
  );
  const cId = colOf("id");
  const cCourse = colOf("course title");
  const cKp = colOf("keypoint #");
  const cHabit = colOf("habit #");
  requireColumns(sheetName, header, {
    "Course Title": cCourse,
    "Keypoint #": cKp,
    "Habit #": cHabit,
  });
  const langCol: Record<Lang, number> = {
    vi: colOf("vi"),
    en: colOf("en"),
    zh: colOf("zh"),
    ja: colOf("ja"),
    ko: colOf("ko"),
  };
  const out: HabitRow[] = [];
  const skipped: SkippedRow[] = [];
  let course = "";
  let kpRef = "";
  rows.forEach((raw, i) => {
    if (isBlankRow(raw)) return;
    const c = str(raw[cCourse]);
    // A new course restarts the keypoint reference. Carrying the previous
    // course's S/KP forward would silently file its habits under the wrong
    // keypoint instead of reporting a missing cell.
    if (c && c !== course) {
      course = c;
      kpRef = "";
    }
    const kpCell = str(raw[cKp]);
    if (kpCell) kpRef = kpCell;
    const habitIndex = parseInt(str(raw[cHabit]), 10);
    const m = /S(\d+)\s*-\s*KP(\d+)/i.exec(kpRef);
    if (!course) {
      skipped.push({ row: rowNumber(i), reason: "no Course Title yet" });
      return;
    }
    if (!m) {
      skipped.push({
        row: rowNumber(i),
        reason: kpRef
          ? `Keypoint # is not S<n>-KP<m> ("${kpRef}") — ${course}`
          : `no Keypoint # yet — ${course}`,
      });
      return;
    }
    if (!Number.isFinite(habitIndex)) {
      skipped.push({
        row: rowNumber(i),
        reason: `Habit # is not a number ("${str(raw[cHabit])}") — ${course} ${kpRef}`,
      });
      return;
    }
    const title = pickLangs({
      vi: str(raw[langCol.vi]),
      en: str(raw[langCol.en]),
      zh: str(raw[langCol.zh]),
      ja: str(raw[langCol.ja]),
      ko: str(raw[langCol.ko]),
    });
    if (!Object.keys(title).length) {
      skipped.push({
        row: rowNumber(i),
        reason: `all language columns empty — ${course} ${kpRef}`,
      });
      return;
    }
    const id = cId >= 0 ? str(raw[cId]) : "";
    out.push({
      ...(id ? { id } : {}),
      course,
      section: parseInt(m[1], 10),
      keypoint: parseInt(m[2], 10),
      habitIndex,
      title,
    });
  });
  return { rows: out, skipped };
}
