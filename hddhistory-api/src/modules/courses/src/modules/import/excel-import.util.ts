import { BadRequestException } from '@nestjs/common';
import ExcelJS from 'exceljs';

export type ImportRow = {
  rowNumber: number;
  values: Record<string, any>;
};

export interface ImportValidationError {
  sheet: string;
  row: number;
  column?: string;
  message: string;
}

export const SUPPORTED_IMPORT_LANGUAGE_CODES = [
  'vi',
  'en',
  'zh',
  'ja',
  'ko',
] as const;

export type ImportLanguageCode =
  (typeof SUPPORTED_IMPORT_LANGUAGE_CODES)[number];

export async function readWorkbook(file: Express.Multer.File) {
  if (!file?.buffer) {
    throw new BadRequestException('Excel file is required');
  }

  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(file.buffer as any);
  return workbook;
}

export function getSheet(
  workbook: ExcelJS.Workbook,
  names: string[],
  required = false,
) {
  const sheet = names
    .map(name => workbook.getWorksheet(name))
    .find(Boolean);

  if (!sheet && required) {
    throw new BadRequestException(`Sheet ${names[0]} is required`);
  }

  return sheet;
}

export function getRows(sheet?: ExcelJS.Worksheet): ImportRow[] {
  if (!sheet) return [];

  const headers = getHeaders(sheet);
  const rows: ImportRow[] = [];

  sheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;

    const values: Record<string, any> = {};
    let hasValue = false;

    headers.forEach((header, index) => {
      const value = normalizeCellValue(row.getCell(index + 1).value);
      values[header] = value;
      hasValue = hasValue || value !== '';
    });

    if (hasValue) {
      rows.push({ rowNumber, values });
    }
  });

  return rows;
}

export function getHeaders(sheet: ExcelJS.Worksheet) {
  const values = sheet.getRow(1).values as ExcelJS.CellValue[];
  return values.slice(1).map(value => String(value).trim());
}

export function setCellByHeader(
  sheet: ExcelJS.Worksheet,
  rowNumber: number,
  header: string,
  value: string,
) {
  const headers = getHeaders(sheet);
  const index = headers.indexOf(header);
  if (index >= 0) {
    sheet.getRow(rowNumber).getCell(index + 1).value = value;
  }
}

export function validateNoDuplicateValues(
  sheet: string,
  rows: ImportRow[],
  errors: ImportValidationError[],
  column = 'id',
) {
  const firstRowByValue = new Map<string, number>();
  for (const row of rows) {
    const value = text(row.values[column]);
    if (!value) continue;

    const firstRow = firstRowByValue.get(value);
    if (firstRow !== undefined) {
      errors.push({
        sheet,
        row: row.rowNumber,
        column,
        message: `${column} is duplicated (already used on row ${firstRow})`,
      });
    } else {
      firstRowByValue.set(value, row.rowNumber);
    }
  }
}

export function assertNoImportErrors(errors: ImportValidationError[]) {
  if (errors.length) {
    throw new BadRequestException({
      message: 'Excel import validation failed',
      errors,
    });
  }
}

export function text(value: any): string {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

export function numberValue(value: any): number | undefined {
  const raw = text(value);
  if (!raw) return undefined;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : undefined;
}

export function translation(vi?: any, en?: any) {
  const result: Record<string, string> = {};
  const viText = text(vi);
  const enText = text(en);
  if (viText) result.vi = viText;
  if (enText) result.en = enText;
  return Object.keys(result).length ? result : undefined;
}

export function hasTranslationValue(vi?: any, en?: any) {
  return Boolean(text(vi) || text(en));
}

export function translationFromValues(
  values: Record<string, any>,
  prefix: string,
  transform?: (value: any) => any,
) {
  const result: Record<string, string> = {};

  for (const lang of SUPPORTED_IMPORT_LANGUAGE_CODES) {
    const rawValue = values[`${prefix}_${lang}`];
    const value = transform ? transform(rawValue) : rawValue;
    const valueText = text(value);
    if (valueText) result[lang] = valueText;
  }

  return Object.keys(result).length ? result : undefined;
}

export function hasTranslationValueForPrefix(
  values: Record<string, any>,
  prefix: string,
) {
  return SUPPORTED_IMPORT_LANGUAGE_CODES.some(lang =>
    Boolean(text(values[`${prefix}_${lang}`])),
  );
}

export function translationColumnLabel(prefix: string) {
  return SUPPORTED_IMPORT_LANGUAGE_CODES.map(lang => `${prefix}_${lang}`).join(
    '/',
  );
}

export function translationHeaders(prefix: string) {
  return SUPPORTED_IMPORT_LANGUAGE_CODES.map(lang => `${prefix}_${lang}`);
}

export function translationCells(value?: Record<string, any> | null) {
  return SUPPORTED_IMPORT_LANGUAGE_CODES.map(lang => text(value?.[lang]));
}

export function splitList(value: any): string[] {
  return text(value)
    .split('|')
    .map(item => item.trim())
    .filter(Boolean);
}

export function resolveAssetUrl(value: any, cdn?: string): string {
  const raw = text(value);
  if (!raw || isFullUrl(raw) || !cdn) return raw;

  const baseUrl = cdn.replace(/\/+$/, '');
  return `${baseUrl}/${resolveAssetFolder(raw)}/${raw.replace(/^\/+/, '')}`;
}

export async function workbookToBuffer(workbook: ExcelJS.Workbook) {
  const output = await workbook.xlsx.writeBuffer();
  return Buffer.from(output);
}

export async function createTemplateWorkbook(
  sheetName: string,
  headers: string[],
  sampleRows: any[][] = [],
) {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet(sheetName);
  sheet.addRow(headers);
  for (const row of sampleRows) {
    sheet.addRow(row);
  }
  return workbookToBuffer(workbook);
}

export interface TemplateSheetDef {
  sheetName: string;
  headers: string[];
  sampleRows?: any[][];
}

export async function createMultiSheetTemplateWorkbook(
  sheets: TemplateSheetDef[],
) {
  const workbook = new ExcelJS.Workbook();
  for (const { sheetName, headers, sampleRows = [] } of sheets) {
    const sheet = workbook.addWorksheet(sheetName);
    sheet.addRow(headers);
    for (const row of sampleRows) {
      sheet.addRow(row);
    }
  }
  return workbookToBuffer(workbook);
}

function normalizeCellValue(value: ExcelJS.CellValue): any {
  if (value === null || value === undefined) return '';
  if (value instanceof Date) return value;
  if (typeof value !== 'object') return value;
  if ('text' in value) return value.text;
  if ('result' in value) return value.result;
  if ('richText' in value) {
    return value.richText.map(item => item.text).join('');
  }
  return String(value);
}

function isFullUrl(value: string) {
  return /^https?:\/\//i.test(value);
}

function resolveAssetFolder(filename: string) {
  const extension = filename.split('.').pop()?.toLowerCase();
  if (['mp3', 'wav', 'm4a', 'ogg'].includes(extension ?? '')) {
    return 'audios';
  }
  if (['mp4', 'mov', 'webm'].includes(extension ?? '')) {
    return 'videos';
  }
  return 'images';
}
