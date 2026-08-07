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
  /**
   * The course this row belongs to. The ONLY thing import matches on.
   *
   * `course` below is the title, written next to it so the sheet stays readable
   * — but it is a label, not a key. Matching on the title meant a rename moved a
   * course's habits nowhere and two courses sharing a title took each other's.
   */
  courseId: string;
  course: string;
  section: number;
  keypoint: number;
  habitIndex: number;
  keypointTitleVi?: string;
  /**
   * The habit's own picture, absolute CDN url. Blank means the app falls back
   * to the skillset logo.
   *
   * A habit repeats across every keypoint that suggests it, so the same url
   * repeats down the column. The server takes the first non-empty one it sees
   * per habit rather than the first cell, so filling it once is enough.
   */
  image?: string;
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
  // Either column marks the header row: the habit sheet is keyed by "Course ID"
  // and may carry no title column at all, while re-anchor still leads with
  // "Course Title".
  let headerIdx = aoa.findIndex((r) =>
    r.some((c) => ["course title", "course id"].includes(str(c).toLowerCase())),
  );
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
      // Two courses can carry the same title; the id keeps their rows in
      // separate blocks instead of interleaving them under one heading.
      a.courseId.localeCompare(b.courseId) ||
      a.section - b.section ||
      a.keypoint - b.keypoint ||
      a.habitIndex - b.habitIndex,
  );
  const header = [
    "ID",
    "Course ID",
    "Course Title",
    "Keypoint #",
    "Keypoint title (VI)",
    "Habit #",
    "Image",
    "VI",
    "EN",
    "ZH",
    "JA",
    "KO",
  ];
  const aoa: (string | number)[][] = [header];
  let prevCourseId = "";
  let prevKp = "";
  for (const r of sorted) {
    const kp = `S${r.section}-KP${r.keypoint}`;
    // Blank-on-repeat (the merged-cell look) is keyed on the id, not the title.
    // Keying it on the title would fold two same-titled courses into one block
    // and leave the second one's rows with no id of their own.
    const sameCourse = r.courseId === prevCourseId;
    aoa.push([
      r.id ?? "", // stable identity — do NOT edit this column
      sameCourse ? "" : r.courseId, // the import key — do NOT edit this column
      sameCourse ? "" : r.course,
      kp === prevKp && sameCourse ? "" : kp,
      r.keypointTitleVi ?? "",
      r.habitIndex,
      r.image ?? "",
      r.title.vi ?? "",
      r.title.en ?? "",
      r.title.zh ?? "",
      r.title.ja ?? "",
      r.title.ko ?? "",
    ]);
    prevCourseId = r.courseId;
    prevKp = kp;
  }
  const ws = XLSX.utils.aoa_to_sheet(aoa);
  // A habit is shared by every keypoint that suggests it, so the file is one
  // row per (habit × keypoint) — on dev that is 974 rows standing in for 24
  // habits, one of them repeated 167 times. Nothing can flatten that without
  // losing the mapping the import needs, so make it navigable instead:
  // autofilter to pull one habit or one course out of the pile, and widths so
  // the id and title columns are readable without dragging every border.
  // (Freeze panes would help too, but xlsx 0.18 community cannot write them.)
  ws["!autofilter"] = {
    ref: XLSX.utils.encode_range({
      s: { r: 0, c: 0 },
      e: { r: 0, c: header.length - 1 },
    }),
  };
  ws["!cols"] = [
    { wch: 26 }, // ID
    { wch: 26 }, // Course ID
    { wch: 34 }, // Course Title
    { wch: 12 }, // Keypoint #
    { wch: 34 }, // Keypoint title (VI)
    { wch: 8 }, // Habit #
    { wch: 40 }, // Image
    { wch: 46 }, // VI
    { wch: 46 }, // EN
    { wch: 30 }, // ZH
    { wch: 30 }, // JA
    { wch: 30 }, // KO
  ];
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
  const cCourseId = colOf("course id");
  // Optional, and never matched on — carried through only so a failed row can
  // be reported by a name a content editor recognises.
  const cCourse = colOf("course title");
  const cKp = colOf("keypoint #");
  const cHabit = colOf("habit #");
  // Optional so a sheet written before the column existed still imports — it
  // just leaves every habit without a picture.
  const cImage = colOf("image");
  requireColumns(sheetName, header, {
    "Course ID": cCourseId,
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
  let courseId = "";
  let course = "";
  let kpRef = "";
  rows.forEach((raw, i) => {
    if (isBlankRow(raw)) return;
    const idCell = str(raw[cCourseId]);
    // A new course restarts the keypoint reference. Carrying the previous
    // course's S/KP forward would silently file its habits under the wrong
    // keypoint instead of reporting a missing cell. Keyed on the id, so two
    // courses that happen to share a title still restart properly.
    if (idCell && idCell !== courseId) {
      courseId = idCell;
      course = "";
      kpRef = "";
    }
    const titleCell = cCourse >= 0 ? str(raw[cCourse]) : "";
    if (titleCell) course = titleCell;
    const kpCell = str(raw[cKp]);
    if (kpCell) kpRef = kpCell;
    const habitIndex = parseInt(str(raw[cHabit]), 10);
    const m = /S(\d+)\s*-\s*KP(\d+)/i.exec(kpRef);
    if (!courseId) {
      skipped.push({ row: rowNumber(i), reason: "no Course ID yet" });
      return;
    }
    // Skip reasons name the course by title where the sheet has one and by id
    // otherwise, since the title column is optional now.
    const label = course || courseId;
    if (!m) {
      skipped.push({
        row: rowNumber(i),
        reason: kpRef
          ? `Keypoint # is not S<n>-KP<m> ("${kpRef}") — ${label}`
          : `no Keypoint # yet — ${label}`,
      });
      return;
    }
    if (!Number.isFinite(habitIndex)) {
      skipped.push({
        row: rowNumber(i),
        reason: `Habit # is not a number ("${str(raw[cHabit])}") — ${label} ${kpRef}`,
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
        reason: `all language columns empty — ${label} ${kpRef}`,
      });
      return;
    }
    const id = cId >= 0 ? str(raw[cId]) : "";
    const imageCell = cImage >= 0 ? str(raw[cImage]) : "";
    out.push({
      ...(id ? { id } : {}),
      courseId,
      course,
      image: imageCell,
      section: parseInt(m[1], 10),
      keypoint: parseInt(m[2], 10),
      habitIndex,
      title,
    });
  });
  return { rows: out, skipped };
}
