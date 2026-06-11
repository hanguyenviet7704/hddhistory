export interface ImageCompressionOptions {
  maxWidthOrHeight?: number;
  quality?: number;
  maxSizeMB?: number;
}

const COMPRESSIBLE_IMAGE_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
]);

const DEFAULT_OPTIONS: Required<ImageCompressionOptions> = {
  maxWidthOrHeight: 1280,
  quality: 0.75,
  maxSizeMB: 0.5,
};

export async function compressImageFile(
  file: File,
  options: ImageCompressionOptions = {},
): Promise<File> {
  if (!COMPRESSIBLE_IMAGE_TYPES.has(file.type)) {
    return file;
  }

  const resolvedOptions = { ...DEFAULT_OPTIONS, ...options };
  const maxSizeBytes = resolvedOptions.maxSizeMB * 1024 * 1024;
  const shouldResizeBySize = file.size > maxSizeBytes;

  const image = await loadImage(file);
  const { width, height } = getTargetDimensions(
    image.width,
    image.height,
    resolvedOptions.maxWidthOrHeight,
  );

  const shouldResizeByDimensions =
    width !== image.width || height !== image.height;

  if (!shouldResizeBySize && !shouldResizeByDimensions) {
    return file;
  }

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;

  const context = canvas.getContext("2d");
  if (!context) {
    return file;
  }

  context.drawImage(image, 0, 0, width, height);

  const outputType = resolveOutputType(file.type);
  const blob = await canvasToBlob(canvas, outputType, resolvedOptions.quality);

  if (!blob || blob.size >= file.size) {
    return file;
  }

  return new File([blob], resolveFileName(file.name, outputType), {
    type: outputType,
    lastModified: file.lastModified,
  });
}

function getTargetDimensions(
  width: number,
  height: number,
  maxWidthOrHeight: number,
) {
  const longestSide = Math.max(width, height);
  if (longestSide <= maxWidthOrHeight) {
    return { width, height };
  }

  const scale = maxWidthOrHeight / longestSide;
  return {
    width: Math.round(width * scale),
    height: Math.round(height * scale),
  };
}

function loadImage(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const image = new Image();

    image.onload = () => {
      URL.revokeObjectURL(url);
      resolve(image);
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Cannot load image for compression"));
    };
    image.src = url;
  });
}

function canvasToBlob(
  canvas: HTMLCanvasElement,
  type: string,
  quality: number,
): Promise<Blob | null> {
  return new Promise((resolve) => {
    canvas.toBlob(resolve, type, quality);
  });
}

function resolveOutputType(inputType: string) {
  if (inputType === "image/jpeg") {
    return "image/jpeg";
  }

  return "image/webp";
}

function resolveFileName(fileName: string, type: string) {
  const extension = type === "image/jpeg" ? "jpg" : "webp";
  const baseName = fileName.replace(/\.[^.]+$/, "");
  return `${baseName}.${extension}`;
}
