'use server';

import { redirect } from 'next/navigation';

import { importErrorText, MAX_PDF_MB } from '@/components/import/import-copy';

import { ApiError, request } from '../api';
import { attempt, describeError, type ActionResult } from '../action-result';
import type { ImportJob } from '../learning-import';

export interface StartImportState {
  error?: string;
  /** Mã để form biết lỗi thuộc ô nào (ô link YouTube hay ô tệp). */
  field?: 'url' | 'file';
}

/** Cùng phép thử thô của app: bắt lỗi gõ nhầm trước khi tốn một request. */
function looksLikeYoutube(url: string): boolean {
  const lower = url.toLowerCase();
  return lower.includes('youtube.com/') || lower.includes('youtu.be/');
}

/**
 * Lời từ chối của `POST /learning-imports` → câu tiếng Việt.
 *
 * API gửi mã máy (`errors[0].code`) nhưng `request()` chỉ giữ `message` và
 * `status`, nên đọc theo status — mỗi bức tường của API dùng một status riêng
 * nên vẫn phân biệt được đủ.
 */
function rejectionText(error: unknown): string {
  if (!(error instanceof ApiError)) return describeError(error);
  switch (error.status) {
    case 503:
      // Hai lý do cùng 503: thiếu khoá AI (lỗi của mình) hoặc admin tắt tính
      // năng — khi tắt, message chính là ghi chú admin viết (hoặc câu tiếng
      // Anh mặc định nếu để trống).
      if (/not configured/i.test(error.message)) {
        return importErrorText('AI_NOT_CONFIGURED');
      }
      return /turned off/i.test(error.message)
        ? 'Tính năng đang tắt một lát. Bài học của bạn vẫn còn nguyên, chỉ là chưa tạo mới được thôi.'
        : error.message;
    case 403:
      return importErrorText('QUOTA_EXCEEDED');
    case 409:
      return importErrorText('JOB_ALREADY_RUNNING');
    case 400:
      if (/youtube/i.test(error.message)) {
        return 'Đây không phải link YouTube hợp lệ.';
      }
      return 'Không đọc được tệp này. Thử tệp khác nhé.';
    default:
      return describeError(error);
  }
}

/**
 * Bắt đầu một lượt tạo bài, đúng như app gửi.
 *
 * PDF đi hai bước như app (`LearningImportCubit.startPdfImport`): tải lên
 * `/cloudflares/upload` trước (thư mục `user_import`, tiền tố `pdf_`) rồi chỉ
 * gửi KHOÁ của tệp sang `/learning-imports` — API tự lấy tệp từ R2, để một
 * giáo trình 20MB không phải nằm trong thân JSON.
 *
 * Ngôn ngữ bài luôn là `vi`: app viết bài bằng ngôn ngữ đang dùng, và web chỉ
 * có tiếng Việt.
 */
export async function startImport(
  _prev: StartImportState | null,
  formData: FormData,
): Promise<StartImportState> {
  const source = String(formData.get('source') ?? 'youtube');

  let body: Record<string, string>;
  if (source === 'pdf') {
    const file = formData.get('file');
    if (!(file instanceof File) || file.size === 0) {
      return { error: 'Chọn một file PDF.', field: 'file' };
    }
    const isPdf =
      file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      return { error: 'Không đọc được tệp này. Thử tệp khác nhé.', field: 'file' };
    }
    if (file.size > MAX_PDF_MB * 1024 * 1024) {
      return { error: importErrorText('PDF_TOO_LARGE'), field: 'file' };
    }

    // KHÔNG gửi `key = tên tệp` như app: API thấy `key` là bỏ qua prefix/folder
    // và lưu thẳng ở gốc bucket với đúng tên đó, nên hai người cùng tải
    // "giao-trinh.pdf" sẽ ghi đè tệp của nhau (và lượt nhập của người này có
    // thể đọc tài liệu của người kia). Tự dựng khoá duy nhất theo đúng mẫu ví
    // dụ trong DTO của API: `user_import/pdf_<thời điểm>_<tên>.pdf`.
    const safeName =
      file.name
        .normalize('NFD')
        .replace(/[̀-ͯ]/g, '')
        .replace(/[^A-Za-z0-9._-]+/g, '-')
        .replace(/-+/g, '-')
        .slice(-80) || 'document.pdf';
    const unique = `${Date.now()}${Math.random().toString(36).slice(2, 8)}`;
    const upload = new FormData();
    upload.append('file', file, file.name);
    upload.append('key', `user_import/pdf_${unique}_${safeName}`);

    let key: string;
    try {
      const uploaded = await request<{ key: string; url: string }>(
        '/api/v1/cloudflares/upload',
        { method: 'POST', body: upload },
      );
      key = uploaded.key;
    } catch (error) {
      return {
        error: `Chưa tải được tệp lên. ${describeError(error)}`,
        field: 'file',
      };
    }
    body = {
      sourceType: 'pdf',
      fileKey: key,
      fileName: file.name,
      outputLocale: 'vi',
    };
  } else {
    const url = String(formData.get('url') ?? '').trim();
    if (!url || !looksLikeYoutube(url)) {
      return { error: 'Đây không phải link YouTube hợp lệ.', field: 'url' };
    }
    body = { sourceType: 'youtube', url, outputLocale: 'vi' };
  }

  let job: ImportJob;
  try {
    job = await request<ImportJob>('/api/v1/learning-imports', {
      method: 'POST',
      body,
    });
  } catch (error) {
    return { error: rejectionText(error) };
  }

  // Màn chờ thay chỗ form, như app `pushReplacement`: quay "lại" một form đã
  // gửi đi rồi thì vô nghĩa.
  redirect(`/nhap-bai/${encodeURIComponent(job.id)}`);
}

/** Một nhịp poll của màn chờ. Không bao giờ ném — một nhịp hỏng thì nhịp sau hỏi lại. */
export async function pollImportJob(
  jobId: string,
): Promise<ActionResult<ImportJob>> {
  return attempt(() =>
    request<ImportJob>(`/api/v1/learning-imports/${encodeURIComponent(jobId)}`, {
      revalidate: 0,
    }),
  );
}
