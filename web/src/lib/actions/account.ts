'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

import { attempt, type ActionResult } from '@/lib/action-result';
import { request } from '@/lib/api';
import {
  clearSession,
  getAccessToken,
  getRefreshToken,
  getSessionUser,
  saveSession,
} from '@/lib/session';

/**
 * Id tài khoản LẤY TỪ PHIÊN, không bao giờ từ form.
 *
 * `PUT /users/:id` và `DELETE /users/:id` của API không kiểm tra chủ sở hữu —
 * gọi với id của người khác là sửa/xoá được tài khoản người đó. Nhận id từ
 * client thì action này thành đúng cái lỗ ấy.
 */
async function ownId(): Promise<string | null> {
  return (await getSessionUser())?.id ?? null;
}

const NOT_SIGNED_IN = 'Phiên đăng nhập đã hết. Đăng nhập lại.';

/** Tên hiện ở header lấy từ cookie phiên — đổi tên thì phải ghi lại cookie. */
async function rememberName(name: string): Promise<void> {
  const [user, access, refresh] = await Promise.all([
    getSessionUser(),
    getAccessToken(),
    getRefreshToken(),
  ]);
  if (user && access && refresh) {
    await saveSession(access, refresh, { ...user, name });
  }
}

export async function updateName(
  _prev: ActionResult<string> | null,
  formData: FormData,
): Promise<ActionResult<string>> {
  const id = await ownId();
  if (!id) return { ok: false, error: NOT_SIGNED_IN };

  const name = String(formData.get('name') ?? '').trim();
  // Cùng điều kiện với app: tên trống thì không gửi.
  if (!name) return { ok: false, error: 'Nhập họ tên.' };
  if (name.length > 80) return { ok: false, error: 'Họ tên dài quá 80 ký tự.' };

  const result = await attempt(() =>
    request(`/api/v1/users/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: { name },
    }),
  );
  if (!result.ok) return result;

  await rememberName(name);
  revalidatePath('/', 'layout');
  return { ok: true, data: name };
}

/** Ảnh đã được thu nhỏ ở trình duyệt; đây chỉ là chốt chặn phía máy chủ. */
const MAX_AVATAR_BYTES = 900 * 1024;

/**
 * Đổi ảnh đại diện: tải ảnh lên R2 rồi lưu URL vào tài khoản — hai request cho
 * một thao tác, đúng như `ProfileCubit.updateAvatar` của app.
 *
 * Khoá đối tượng có dấu thời gian để mỗi lần tải là một URL mới: ghi đè cùng
 * một khoá thì mọi nơi đã cache URL cũ (trình duyệt, CDN) vẫn hiện ảnh cũ.
 */
export async function updateAvatar(
  formData: FormData,
): Promise<ActionResult<string>> {
  const id = await ownId();
  if (!id) return { ok: false, error: NOT_SIGNED_IN };

  const file = formData.get('file');
  if (!(file instanceof File) || file.size === 0) {
    return { ok: false, error: 'Chưa chọn ảnh.' };
  }
  if (!file.type.startsWith('image/')) {
    return { ok: false, error: 'Tệp này không phải ảnh.' };
  }
  if (file.size > MAX_AVATAR_BYTES) {
    return { ok: false, error: 'Ảnh quá lớn. Chọn ảnh khác.' };
  }

  const ext = file.type === 'image/png' ? 'png' : file.type === 'image/webp' ? 'webp' : 'jpg';
  const upload = new FormData();
  upload.append('file', file, `avatar.${ext}`);
  upload.append('key', `user_avatar/${id}-${Date.now()}.${ext}`);
  upload.append('prefix', '');
  upload.append('folder', '');

  const result = await attempt(async () => {
    const { url } = await request<{ key: string; url: string }>(
      '/api/v1/cloudflares/upload',
      { method: 'POST', body: upload },
    );
    await request(`/api/v1/users/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: { avatar: url },
    });
    return url;
  });
  if (result.ok) revalidatePath('/ho-so', 'layout');
  return result;
}

/**
 * Xoá tài khoản vĩnh viễn — cùng đường app dùng (`DELETE /users/:id`, xoá cả
 * tiến độ học). `delete-my-account` mà app cũng khai báo không tồn tại ở API.
 *
 * Chỉ chạy khi form gửi kèm `confirm=yes` từ bước xác nhận: một POST lạc (bấm
 * nhầm, gửi lại form) không được phép xoá dữ liệu của ai.
 */
export async function deleteAccount(
  _prev: ActionResult | null,
  formData: FormData,
): Promise<ActionResult> {
  const id = await ownId();
  if (!id) return { ok: false, error: NOT_SIGNED_IN };
  if (formData.get('confirm') !== 'yes') {
    return { ok: false, error: 'Chưa xác nhận xoá tài khoản.' };
  }

  const result = await attempt(() =>
    request(`/api/v1/users/${encodeURIComponent(id)}`, { method: 'DELETE' }),
  );
  if (!result.ok) return { ok: false, error: result.error };

  await clearSession();
  redirect('/dang-nhap');
}
