// CSV/Excel Import Wizard — Column mapping and parsing (D-115)
// Threat: T-19-39 — Validate CSV content, limit file size, sanitize cell values

// ---------- Constants ----------

/** Maximum CSV file size: 10MB (T-19-39) */
const MAX_FILE_SIZE = 10 * 1024 * 1024;

/** Maximum cell value length after sanitization */
const MAX_CELL_LENGTH = 5_000;

/** Maximum number of rows to parse */
const MAX_ROWS = 50_000;

// ---------- Types ----------

export type CSVRow = Record<string, string>;

export type ColumnType = "text" | "numeric" | "date" | "boolean" | "empty";

export type ColumnInfo = {
  name: string;
  detectedType: ColumnType;
  sampleValues: string[];
  nullCount: number;
};

export type ColumnMapping = {
  sourceColumn: string;
  targetColumn: string;
  transform?: (value: string) => string;
};

export type CSVParseResult = {
  rows: CSVRow[];
  headers: string[];
  rowCount: number;
  errors: string[];
};

export type MappedData<T = Record<string, unknown>> = {
  rows: T[];
  unmappedColumns: string[];
  errors: string[];
};

// ---------- Procore Mapping Templates (D-115) ----------

export const PROCORE_MAPPINGS: Record<string, ColumnMapping[]> = {
  projects: [
    { sourceColumn: "Project Name", targetColumn: "name" },
    { sourceColumn: "Project Number", targetColumn: "id" },
    { sourceColumn: "Status", targetColumn: "status" },
    { sourceColumn: "Start Date", targetColumn: "start_date" },
    { sourceColumn: "Estimated Completion", targetColumn: "end_date" },
    { sourceColumn: "Contract Value", targetColumn: "budget" },
    { sourceColumn: "Client", targetColumn: "client" },
  ],
  budgetItems: [
    { sourceColumn: "Cost Code", targetColumn: "code" },
    { sourceColumn: "Description", targetColumn: "description" },
    { sourceColumn: "Original Budget", targetColumn: "original_amount" },
    { sourceColumn: "Approved COs", targetColumn: "change_order_amount" },
    { sourceColumn: "Revised Budget", targetColumn: "revised_amount" },
    { sourceColumn: "Committed Costs", targetColumn: "committed" },
    { sourceColumn: "Actual Costs", targetColumn: "actual" },
  ],
  changeOrders: [
    { sourceColumn: "CO #", targetColumn: "number" },
    { sourceColumn: "Title", targetColumn: "description" },
    { sourceColumn: "Amount", targetColumn: "amount" },
    { sourceColumn: "Status", targetColumn: "status" },
    { sourceColumn: "Created Date", targetColumn: "created_at" },
    { sourceColumn: "Approved Date", targetColumn: "approved_at" },
  ],
};

// ---------- Sanitization (T-19-39) ----------

/**
 * Sanitize a cell value to prevent injection and limit size.
 * Strips formula prefixes (=, +, -, @) that could trigger CSV injection.
 */
function sanitizeCell(value: string): string {
  let v = value.trim();

  // Strip CSV formula injection prefixes
  if (/^[=+\-@]/.test(v)) {
    v = v.replace(/^[=+\-@]+/, "");
  }

  // Remove null bytes
  v = v.replace(/\0/g, "");

  // Truncate to max length
  if (v.length > MAX_CELL_LENGTH) {
    v = v.slice(0, MAX_CELL_LENGTH);
  }

  return v;
}

// ---------- CSV Parsing ----------

/**
 * Parse a CSV string into an array of row objects.
 * Handles quoted fields, escaped quotes, and newlines within quotes.
 *
 * @param csvString - Raw CSV content
 * @returns Parsed rows with headers and error list
 */
export function parseCSV(csvString: string): CSVParseResult {
  const errors: string[] = [];

  // T-19-39: file size check
  const byteSize = new Blob([csvString]).size;
  if (byteSize > MAX_FILE_SIZE) {
    return {
      rows: [],
      headers: [],
      rowCount: 0,
      errors: [`File exceeds maximum size of ${MAX_FILE_SIZE / 1024 / 1024}MB`],
    };
  }

  // Normalize line endings
  const normalized = csvString.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  // Parse fields handling quoted values
  const lines: string[][] = [];
  let currentLine: string[] = [];
  let currentField = "";
  let inQuotes = false;

  for (let i = 0; i < normalized.length; i++) {
    const ch = normalized[i];

    if (inQuotes) {
      if (ch === '"') {
        // Check for escaped quote
        if (i + 1 < normalized.length && normalized[i + 1] === '"') {
          currentField += '"';
          i++; // skip next quote
        } else {
          inQuotes = false;
        }
      } else {
        currentField += ch;
      }
    } else {
      if (ch === '"') {
        inQuotes = true;
      } else if (ch === ",") {
        currentLine.push(currentField);
        currentField = "";
      } else if (ch === "\n") {
        currentLine.push(currentField);
        currentField = "";
        lines.push(currentLine);
        currentLine = [];

        // Row limit check
        if (lines.length > MAX_ROWS + 1) {
          errors.push(`Truncated at ${MAX_ROWS} rows (file has more).`);
          break;
        }
      } else {
        currentField += ch;
      }
    }
  }

  // Last field/line
  if (currentField || currentLine.length > 0) {
    currentLine.push(currentField);
    lines.push(currentLine);
  }

  if (lines.length === 0) {
    return { rows: [], headers: [], rowCount: 0, errors: ["Empty CSV file."] };
  }

  // First row = headers
  const headers = lines[0].map((h) => sanitizeCell(h));

  // Check for duplicate headers
  const headerSet = new Set<string>();
  for (const h of headers) {
    if (headerSet.has(h)) {
      errors.push(`Duplicate header: "${h}"`);
    }
    headerSet.add(h);
  }

  // Data rows
  const rows: CSVRow[] = [];
  for (let r = 1; r < lines.length; r++) {
    const line = lines[r];

    // Skip completely empty lines
    if (line.length === 1 && line[0].trim() === "") continue;

    const row: CSVRow = {};
    for (let c = 0; c < headers.length; c++) {
      const raw = c < line.length ? line[c] : "";
      row[headers[c]] = sanitizeCell(raw);
    }

    // Flag rows with extra columns
    if (line.length > headers.length) {
      errors.push(`Row ${r} has ${line.length - headers.length} extra column(s).`);
    }

    rows.push(row);
  }

  return { rows, headers, rowCount: rows.length, errors };
}

// ---------- Column Detection ----------

/**
 * Auto-detect column types from parsed data.
 * Samples up to 100 rows for type inference.
 */
export function detectColumns(data: CSVRow[]): ColumnInfo[] {
  if (data.length === 0) return [];

  const headers = Object.keys(data[0]);
  const sampleSize = Math.min(data.length, 100);
  const sample = data.slice(0, sampleSize);

  return headers.map((name) => {
    const values = sample.map((r) => r[name] ?? "");
    const nonEmpty = values.filter((v) => v.trim() !== "");
    const nullCount = values.length - nonEmpty.length;
    const sampleValues = nonEmpty.slice(0, 5);

    if (nonEmpty.length === 0) {
      return { name, detectedType: "empty" as ColumnType, sampleValues, nullCount };
    }

    // Check numeric
    const numericCount = nonEmpty.filter((v) => {
      const cleaned = v.replace(/[$,%\s]/g, "");
      return !isNaN(Number(cleaned)) && cleaned !== "";
    }).length;

    if (numericCount / nonEmpty.length >= 0.8) {
      return { name, detectedType: "numeric" as ColumnType, sampleValues, nullCount };
    }

    // Check date patterns
    const datePatterns = [
      /^\d{4}-\d{2}-\d{2}/, // ISO
      /^\d{1,2}\/\d{1,2}\/\d{2,4}/, // US format
      /^\w+ \d{1,2},? \d{4}/, // "Jan 15, 2026"
    ];
    const dateCount = nonEmpty.filter((v) =>
      datePatterns.some((p) => p.test(v.trim()))
    ).length;

    if (dateCount / nonEmpty.length >= 0.7) {
      return { name, detectedType: "date" as ColumnType, sampleValues, nullCount };
    }

    // Check boolean
    const boolValues = new Set(["true", "false", "yes", "no", "1", "0", "y", "n"]);
    const boolCount = nonEmpty.filter((v) => boolValues.has(v.toLowerCase().trim())).length;

    if (boolCount / nonEmpty.length >= 0.9) {
      return { name, detectedType: "boolean" as ColumnType, sampleValues, nullCount };
    }

    return { name, detectedType: "text" as ColumnType, sampleValues, nullCount };
  });
}

// ---------- Column Mapping ----------

/**
 * Apply user-defined column mapping to transform CSV data into a target schema.
 * Unmatched source columns are listed in unmappedColumns.
 */
export function mapColumns<T = Record<string, unknown>>(
  data: CSVRow[],
  mapping: ColumnMapping[]
): MappedData<T> {
  const errors: string[] = [];
  const mappedSourceCols = new Set(mapping.map((m) => m.sourceColumn));
  const allSourceCols = data.length > 0 ? Object.keys(data[0]) : [];
  const unmappedColumns = allSourceCols.filter((c) => !mappedSourceCols.has(c));

  const rows: T[] = data.map((row, idx) => {
    const mapped: Record<string, unknown> = {};

    for (const m of mapping) {
      const rawValue = row[m.sourceColumn];
      if (rawValue === undefined) {
        if (idx === 0) {
          errors.push(`Source column "${m.sourceColumn}" not found in data.`);
        }
        mapped[m.targetColumn] = null;
      } else {
        mapped[m.targetColumn] = m.transform ? m.transform(rawValue) : rawValue;
      }
    }

    return mapped as T;
  });

  return { rows, unmappedColumns, errors };
}
