import * as XLSX from "xlsx";

import { IQuote, QuotePayload } from "../types/interface/quote.interface";
import { ITranslation } from "./translate";

/// Column order of the quote sheet. English FIRST because it is the fallback
/// the notification dispatcher resolves to (`translations[userLang] ||
/// translations.en`): a row missing EN reaches nobody, a row missing any other
/// locale simply reads in English.
const LANG_COLUMNS = ["en", "vi", "zh", "ja", "ko"] as const;
const HEADER = [...LANG_COLUMNS, "backgroundColor", "textColor"];

const DEFAULT_BACKGROUND = "#362F82";
const DEFAULT_TEXT = "#FFFFFF";

const str = (value: unknown): string =>
  value === null || value === undefined ? "" : String(value).trim();

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

/// One row per quote, one column per locale — the shape a non-developer can
/// actually fill in. Exporting the current set first is the intended way to get
/// a template: the header is then guaranteed to match what the importer reads.
export function downloadQuotesXlsx(quotes: IQuote[]) {
  const aoa: string[][] = [
    HEADER,
    ...quotes.map((quote) => [
      ...LANG_COLUMNS.map((code) => str(quote.content?.[code])),
      str(quote.backgroundColor) || DEFAULT_BACKGROUND,
      str(quote.textColor) || DEFAULT_TEXT,
    ]),
  ];

  const ws = XLSX.utils.aoa_to_sheet(aoa);
  ws["!cols"] = [
    ...LANG_COLUMNS.map(() => ({ wch: 52 })),
    { wch: 16 },
    { wch: 16 },
  ];
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "Quotes");
  triggerDownload(wb, "quotes.xlsx");
}

/// A parsed sheet row, already in the payload shape the API takes.
export type ParsedQuoteRow = QuotePayload & { rowNumber: number };

/// Reads the first worksheet into quote payloads.
///
/// Locates the header by looking for the `en` column rather than assuming row 1,
/// so a sheet with a title or note above the table still imports. Rows with no
/// English text are dropped here rather than sent: the API would accept them and
/// they would then be quotes that never reach a single user.
export async function parseQuotesXlsx(file: File): Promise<ParsedQuoteRow[]> {
  const data = await file.arrayBuffer();
  const wb = XLSX.read(data, { type: "array" });
  const ws = wb.Sheets[wb.SheetNames[0]];
  if (!ws) throw new Error("File không có sheet nào");

  const aoa = XLSX.utils.sheet_to_json<string[]>(ws, {
    header: 1,
    defval: "",
    blankrows: false,
  });

  let headerIdx = aoa.findIndex((row) =>
    row.some((cell) => str(cell).toLowerCase() === "en")
  );
  if (headerIdx < 0) headerIdx = 0;

  const header = (aoa[headerIdx] || []).map((cell) => str(cell).toLowerCase());
  const colOf = (name: string) => header.indexOf(name.toLowerCase());

  if (colOf("en") < 0) {
    throw new Error(
      'Không tìm thấy cột "en". Export một file mẫu trước rồi điền vào đó.'
    );
  }

  const rows: ParsedQuoteRow[] = [];
  for (let index = headerIdx + 1; index < aoa.length; index++) {
    const row = aoa[index] || [];
    const cell = (name: string) => {
      const at = colOf(name);
      return at < 0 ? "" : str(row[at]);
    };

    const content: ITranslation = {};
    for (const code of LANG_COLUMNS) {
      const text = cell(code);
      if (text) content[code] = text;
    }
    if (!content.en) continue;

    rows.push({
      content,
      backgroundColor: cell("backgroundColor") || DEFAULT_BACKGROUND,
      textColor: cell("textColor") || DEFAULT_TEXT,
      // 1-based and counting the header, so it matches what Excel shows in the
      // row gutter — the point of reporting it at all is to be findable.
      rowNumber: index + 1,
    });
  }

  if (rows.length === 0) {
    throw new Error("Không có dòng nào có nội dung tiếng Anh");
  }
  return rows;
}
