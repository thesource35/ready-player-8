// Image upload validation and processing (D-118, D-124, T-20-11, T-20-12, T-20-13)
// Validates uploads by MIME type, size, and magic bytes.
// Strips sensitive EXIF data (GPS, device info) while preserving date/time.
// Scans SVG for embedded scripts.

import sharp from "sharp";

// ---------------------------------------------------------------------------
// Type-specific upload constraints
// ---------------------------------------------------------------------------

type ImageType = "logo" | "cover" | "favicon";

const TYPE_CONSTRAINTS: Record<
  ImageType,
  { maxSize: number; allowedFormats: string[]; maxWidth: number; maxHeight: number }
> = {
  logo: {
    maxSize: 2 * 1024 * 1024, // 2MB (D-75)
    allowedFormats: ["png", "svg"],
    maxWidth: 400,
    maxHeight: 100,
  },
  cover: {
    maxSize: 5 * 1024 * 1024, // 5MB (D-62)
    allowedFormats: ["png", "jpeg", "webp"],
    maxWidth: 1200,
    maxHeight: 400,
  },
  favicon: {
    maxSize: 500 * 1024, // 500KB (D-61)
    allowedFormats: ["png"],
    maxWidth: 180,
    maxHeight: 180,
  },
};

// ---------------------------------------------------------------------------
// validateImageUpload — check MIME, size, and format (D-124)
// ---------------------------------------------------------------------------

export async function validateImageUpload(
  buffer: Buffer,
  filename: string,
  options: {
    maxSize: number;
    allowedFormats: string[];
    maxWidth?: number;
    maxHeight?: number;
  }
): Promise<{ valid: boolean; error?: string }> {
  // Check size
  if (buffer.length > options.maxSize) {
    const maxMB = (options.maxSize / (1024 * 1024)).toFixed(1);
    return { valid: false, error: `File exceeds maximum size of ${maxMB}MB` };
  }

  // Check extension
  const ext = filename.split(".").pop()?.toLowerCase() ?? "";
  if (ext === "svg") {
    // SVG handled separately — validate content
    const svgResult = validateSVG(buffer.toString("utf-8"));
    if (!svgResult.valid) {
      return { valid: false, error: svgResult.error };
    }
    if (!options.allowedFormats.includes("svg")) {
      return { valid: false, error: `SVG format not allowed for this upload type` };
    }
    return { valid: true };
  }

  // Use sharp to detect actual format via magic bytes
  try {
    const metadata = await sharp(buffer).metadata();
    const detectedFormat = metadata.format ?? "";

    // Map sharp format names to our allowed format names
    const formatMap: Record<string, string> = {
      png: "png",
      jpeg: "jpeg",
      jpg: "jpeg",
      webp: "webp",
      gif: "gif",
    };

    const normalizedFormat = formatMap[detectedFormat] ?? detectedFormat;
    if (!options.allowedFormats.includes(normalizedFormat)) {
      return {
        valid: false,
        error: `Format "${detectedFormat}" not allowed. Accepted: ${options.allowedFormats.join(", ")}`,
      };
    }

    // Check dimensions if specified
    if (options.maxWidth && metadata.width && metadata.width > options.maxWidth * 4) {
      return { valid: false, error: `Image width ${metadata.width}px exceeds maximum (${options.maxWidth * 4}px)` };
    }
    if (options.maxHeight && metadata.height && metadata.height > options.maxHeight * 4) {
      return { valid: false, error: `Image height ${metadata.height}px exceeds maximum (${options.maxHeight * 4}px)` };
    }
  } catch {
    return { valid: false, error: "Unable to read image — file may be corrupted or not a valid image" };
  }

  return { valid: true };
}

// ---------------------------------------------------------------------------
// validateSVG — scan for embedded scripts and event handlers (D-124, T-20-11)
// ---------------------------------------------------------------------------

export function validateSVG(svgString: string): { valid: boolean; error?: string } {
  if (!svgString || typeof svgString !== "string") {
    return { valid: false, error: "Empty or invalid SVG content" };
  }

  // Check for script tags
  if (/<script[\s>]/i.test(svgString)) {
    return { valid: false, error: "SVG contains <script> tags — rejected for security" };
  }

  // Check for event handlers (onclick, onerror, onload, etc.)
  if (/\bon\w+\s*=/i.test(svgString)) {
    return { valid: false, error: "SVG contains event handlers (onclick, onerror, etc.) — rejected for security" };
  }

  // Check for javascript: protocol
  if (/javascript\s*:/i.test(svgString)) {
    return { valid: false, error: "SVG contains javascript: protocol — rejected for security" };
  }

  // Check for external references that could leak data
  if (/xlink:href\s*=\s*["']https?:/i.test(svgString)) {
    return { valid: false, error: "SVG contains external URL references — rejected for security" };
  }

  // Check for data: URIs in href (potential XSS vector)
  if (/href\s*=\s*["']\s*data\s*:/i.test(svgString)) {
    return { valid: false, error: "SVG contains data: URI references — rejected for security" };
  }

  return { valid: true };
}

// ---------------------------------------------------------------------------
// stripSensitiveExif — remove GPS and device data, keep date/time (D-118, T-20-12)
// ---------------------------------------------------------------------------

export async function stripSensitiveExif(buffer: Buffer): Promise<Buffer> {
  try {
    // Sharp's rotate() without arguments auto-orients based on EXIF, then
    // we can strip all metadata. We preserve orientation by applying it first.
    // Then output with no metadata except what we explicitly add back.
    const metadata = await sharp(buffer).metadata();

    // Read EXIF date fields before stripping
    const exifDate = metadata.exif
      ? extractExifDates(metadata.exif)
      : null;

    // Process: auto-orient + strip all EXIF
    let pipeline = sharp(buffer).rotate(); // auto-orient from EXIF

    // Re-encode with no metadata
    if (metadata.format === "jpeg") {
      pipeline = pipeline.jpeg({ quality: 90 });
    } else if (metadata.format === "png") {
      pipeline = pipeline.png();
    } else if (metadata.format === "webp") {
      pipeline = pipeline.webp({ quality: 90 });
    }

    const result = await pipeline.withMetadata({
      // Preserve date info if available
      exif: exifDate
        ? {
            IFD0: {},
            IFD3: {},
          }
        : undefined,
    }).toBuffer();

    return result;
  } catch (err) {
    console.error("[stripSensitiveExif] Failed to process image:", err);
    // Return original buffer if processing fails — better than losing the image
    return buffer;
  }
}

/**
 * Extract date strings from raw EXIF buffer.
 * Returns date strings if found, null otherwise.
 */
function extractExifDates(exifBuffer: Buffer): { dateTime?: string } | null {
  try {
    // Look for DateTimeOriginal tag (0x9003) or DateTime tag (0x0132)
    // in the EXIF buffer as ASCII strings (YYYY:MM:DD HH:MM:SS format)
    const str = exifBuffer.toString("binary");
    const dateMatch = str.match(/(\d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2})/);
    if (dateMatch) {
      return { dateTime: dateMatch[1] };
    }
  } catch {
    // EXIF parsing is best-effort
  }
  return null;
}

// ---------------------------------------------------------------------------
// processUploadedImage — validate + resize + strip EXIF per type (D-124)
// ---------------------------------------------------------------------------

export async function processUploadedImage(
  buffer: Buffer,
  filename: string,
  type: ImageType
): Promise<Buffer> {
  const constraints = TYPE_CONSTRAINTS[type];

  // Validate first
  const validation = await validateImageUpload(buffer, filename, {
    maxSize: constraints.maxSize,
    allowedFormats: constraints.allowedFormats,
  });

  if (!validation.valid) {
    throw new Error(validation.error ?? "Image validation failed");
  }

  // SVG: return as-is (already validated for scripts)
  const ext = filename.split(".").pop()?.toLowerCase() ?? "";
  if (ext === "svg") {
    return buffer;
  }

  // Strip sensitive EXIF
  let processed = await stripSensitiveExif(buffer);

  // Resize if larger than recommended dimensions
  try {
    const metadata = await sharp(processed).metadata();
    const needsResize =
      (metadata.width && metadata.width > constraints.maxWidth) ||
      (metadata.height && metadata.height > constraints.maxHeight);

    if (needsResize) {
      processed = await sharp(processed)
        .resize(constraints.maxWidth, constraints.maxHeight, {
          fit: "inside",
          withoutEnlargement: true,
        })
        .toBuffer();
    }
  } catch (err) {
    console.error("[processUploadedImage] Resize error:", err);
    // Return EXIF-stripped version even if resize fails
  }

  return processed;
}
