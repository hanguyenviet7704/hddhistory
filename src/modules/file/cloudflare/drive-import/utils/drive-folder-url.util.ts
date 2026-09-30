import { BadRequestException } from '@nestjs/common';

export function extractDriveFolderId(folderUrl: string): string {
  let url: URL;
  try {
    url = new URL(folderUrl);
  } catch {
    throw new BadRequestException('Invalid Google Drive folder URL');
  }

  if (!url.hostname.includes('drive.google.com')) {
    throw new BadRequestException('Only Google Drive folder URLs are allowed');
  }

  const folderMatch = url.pathname.match(/\/folders\/([^/?#]+)/);
  const idFromPath = folderMatch?.[1];
  const idFromQuery = url.searchParams.get('id');
  const folderId = idFromPath || idFromQuery;

  if (!folderId) {
    throw new BadRequestException('Google Drive folder id was not found');
  }

  return folderId;
}
