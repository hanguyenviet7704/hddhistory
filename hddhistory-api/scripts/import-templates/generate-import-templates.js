const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');

const { sharedRules, templates } = require('./template-data');

const outputDir = path.resolve(
  __dirname,
  '..',
  '..',
  'import-templates',
  'excel',
);

function autosizeColumns(sheet, minWidth = 14, maxWidth = 60) {
  sheet.columns.forEach(column => {
    let width = minWidth;
    column.eachCell({ includeEmpty: true }, cell => {
      const value = cell.value == null ? '' : String(cell.value);
      width = Math.max(width, Math.min(maxWidth, value.length + 2));
    });
    column.width = width;
  });
}

function applyHeaderStyle(row) {
  row.font = { bold: true, color: { argb: 'FFFFFFFF' } };
  row.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
  row.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF1F4E78' },
  };
  row.height = 22;
}

function getDataSheets(template) {
  if (Array.isArray(template.dataSheets) && template.dataSheets.length) {
    return template.dataSheets;
  }

  return [
    {
      sheetName: template.sheetName,
      columns: template.columns,
      sampleRows: template.sampleRows,
    },
  ];
}

function addInstructionsSheet(workbook, template) {
  const sheet = workbook.addWorksheet('instructions');
  sheet.columns = [
    { header: 'Section', key: 'section', width: 20 },
    { header: 'Content', key: 'content', width: 110 },
  ];
  applyHeaderStyle(sheet.getRow(1));

  sheet.addRow(['Muc dich', template.context]);
  sharedRules.forEach((rule, index) => {
    sheet.addRow([`Rule ${index + 1}`, rule]);
  });

  getDataSheets(template).forEach(dataSheet => {
    sheet.addRow(['Sheet', dataSheet.sheetName]);
    dataSheet.columns.forEach(([name, required, description]) => {
      sheet.addRow([
        `Column ${name}`,
        `${required.toUpperCase()} - ${description}`,
      ]);
    });
  });

  sheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;
    row.alignment = { vertical: 'top', wrapText: true };
  });
}

function addSampleSheet(workbook, dataSheet) {
  const sheet = workbook.addWorksheet(dataSheet.sheetName);
  sheet.views = [{ state: 'frozen', ySplit: 1 }];
  sheet.columns = dataSheet.columns.map(([name]) => ({
    header: name,
    key: name,
  }));

  applyHeaderStyle(sheet.getRow(1));
  dataSheet.sampleRows.forEach(row => sheet.addRow(row));
  sheet.eachRow((row, rowNumber) => {
    if (rowNumber === 1) return;
    row.alignment = { vertical: 'top', wrapText: true };
  });
  autosizeColumns(sheet);
}

async function generateWorkbook(template) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'Codex';
  workbook.lastModifiedBy = 'Codex';
  workbook.created = new Date();
  workbook.modified = new Date();
  workbook.subject = template.title;
  workbook.title = template.title;

  if (!template.skipInstructions) {
    addInstructionsSheet(workbook, template);
  }
  getDataSheets(template).forEach(dataSheet => {
    addSampleSheet(workbook, dataSheet);
  });

  const filePath = path.join(outputDir, template.fileName);
  await workbook.xlsx.writeFile(filePath);
  return filePath;
}

async function main() {
  fs.mkdirSync(outputDir, { recursive: true });

  const generated = [];
  for (const template of templates) {
    generated.push(await generateWorkbook(template));
  }

  process.stdout.write(`${generated.join('\n')}\n`);
}

main().catch(error => {
  process.stderr.write(`${error.stack}\n`);
  process.exit(1);
});
