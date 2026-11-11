import { of, throwError } from 'rxjs';

import { UserRole } from 'src/modules/user/src/modules/auth/enum/user.enum';

import { AdminAuditInterceptor } from './admin-audit.interceptor';
import { AdminAuditService } from './admin-audit.service';

/**
 * Interceptor này chạy trên MỌI request của cả API, nên hai chỗ nó sai đều đắt:
 * ghi nhầm lưu lượng của app thì bảng phình theo từng lượt Coach và từng bước
 * tiến độ, còn ghi nguyên body thì token với mật khẩu nằm thẳng trong nhật ký.
 * `tsc` và `nest build` không thấy được cái nào trong hai cái đó.
 */
describe('AdminAuditInterceptor', () => {
  let recorded: any[];
  let interceptor: AdminAuditInterceptor;

  const service = {
    record: (row: any) => recorded.push(row),
  } as unknown as AdminAuditService;

  /** Request từ trang quản trị — đúng thứ panel gắn lên mọi lệnh gọi. */
  const fromPanel = { 'x-admin-panel': '1' };

  function contextOf(request: any, statusCode = 200) {
    return {
      getType: () => 'http',
      switchToHttp: () => ({
        getRequest: () => request,
        getResponse: () => ({ statusCode }),
      }),
    } as any;
  }

  const admin = {
    id: 'u1',
    email: 'admin@eupgroup.net',
    name: 'Hà',
    role: UserRole.ADMIN,
  };

  function run(request: any, handler = { handle: () => of('ok') }) {
    return new Promise<void>((resolve, reject) => {
      interceptor
        .intercept(contextOf(request), handler as any)
        .subscribe({ next: () => resolve(), error: () => resolve(), complete: () => resolve() });
      setTimeout(reject, 1000);
    });
  }

  beforeEach(() => {
    recorded = [];
    interceptor = new AdminAuditInterceptor(service);
  });

  it('KHÔNG ghi lượt đọc — ai xem cái gì không phải việc của nhật ký này', async () => {
    await run({ method: 'GET', originalUrl: '/api/v1/courses', user: admin, body: {} });

    expect(recorded).toHaveLength(0);
  });

  it('KHÔNG ghi lưu lượng của APP — đây là thứ giữ bảng khỏi phình', async () => {
    await run({
      method: 'POST',
      originalUrl: '/api/v1/coach/sessions/abc/turns',
      user: { id: 'u9', role: UserRole.USER, email: '', name: '' },
      body: { kind: 'text', text: 'hôm nay mệt' },
    });

    expect(recorded).toHaveLength(0);
  });

  it('KHÔNG ghi khi chưa đăng nhập', async () => {
    await run({ method: 'POST', originalUrl: '/api/v1/users/login', body: {} });

    expect(recorded).toHaveLength(0);
  });

  it('ghi thao tác GHI của admin, kèm người và đường dẫn', async () => {
    await run({
      method: 'PUT',
      originalUrl: '/api/v1/paywall-config?draft=1',
      route: { path: '/paywall-config' },
      headers: fromPanel,
      user: admin,
      body: { giftCampaign: { enabled: true } },
    });

    expect(recorded).toHaveLength(1);
    expect(recorded[0]).toMatchObject({
      actorId: 'u1',
      actorEmail: 'admin@eupgroup.net',
      method: 'PUT',
      // Query string bị bỏ: nó không phải thao tác, và hay mang theo token.
      path: '/api/v1/paywall-config',
      route: '/paywall-config',
      ok: true,
    });
    expect(recorded[0].body).toContain('giftCampaign');
  });

  it('CHE secret trong nội dung — nhật ký không được trở thành chỗ rò token', async () => {
    await run({
      method: 'POST',
      originalUrl: '/api/v1/users/login',
      headers: fromPanel,
      user: admin,
      body: { email: 'a@b.c', password: 'sieubimat', accessToken: 'xyz' },
    });

    const body = recorded[0].body as string;
    expect(body).not.toContain('sieubimat');
    expect(body).not.toContain('xyz');
    // Nhưng thứ không nhạy cảm thì vẫn phải đọc được, không thì nhật ký vô dụng.
    expect(body).toContain('a@b.c');
  });

  it('nội dung quá dài thì cắt, và ĐÁNH DẤU là đã cắt', async () => {
    await run({
      method: 'PUT',
      originalUrl: '/api/v1/paywall-config',
      headers: fromPanel,
      user: admin,
      body: { blob: 'x'.repeat(20_000) },
    });

    expect(recorded[0].bodyTruncated).toBe(true);
    expect((recorded[0].body as string).length).toBeLessThanOrEqual(8_000);
  });

  it('thao tác HỎNG cũng vào sổ — "ai đã thử làm gì" là câu hỏi thật', async () => {
    await run(
      {
        method: 'DELETE',
        originalUrl: '/api/v1/coach-situations/abc',
        headers: fromPanel,
        user: admin,
        body: {},
      },
      { handle: () => throwError(() => ({ status: 403, message: 'Forbidden' })) },
    );

    expect(recorded).toHaveLength(1);
    expect(recorded[0]).toMatchObject({
      ok: false,
      statusCode: 403,
      errorMessage: 'Forbidden',
    });
  });

  it('TÀI KHOẢN role USER nhưng gọi TỪ PANEL thì vẫn vào sổ', async () => {
    // Đây là cả lý do bộ lọc không dùng vai trò: tài khoản đang vận hành panel
    // mang `role: USER` trong database, nên lọc theo vai trò cho ra nhật ký
    // trống trơn — đúng thứ đã xảy ra trên dev.
    await run({
      method: 'PUT',
      originalUrl: '/api/v1/paywall-config',
      headers: fromPanel,
      user: { id: 'u2', email: 'op@eupgroup.net', name: 'HDDhistory', role: UserRole.USER },
      body: { enabled: true },
    });

    expect(recorded).toHaveLength(1);
    expect(recorded[0].actorEmail).toBe('op@eupgroup.net');
  });

  it('cùng tài khoản đó, nhưng gọi TỪ APP thì không vào sổ', async () => {
    await run({
      method: 'POST',
      originalUrl: '/api/v1/coach/sessions/abc/turns',
      headers: {},
      user: { id: 'u2', email: 'op@eupgroup.net', name: 'HDDhistory', role: UserRole.USER },
      body: { kind: 'text', text: 'hôm nay mệt' },
    });

    expect(recorded).toHaveLength(0);
  });

  it('tài khoản ADMIN thật thì vào sổ kể cả không có dấu hiệu panel', async () => {
    await run({
      method: 'DELETE',
      originalUrl: '/api/v1/coach-situations/abc',
      headers: {},
      user: admin,
      body: {},
    });

    expect(recorded).toHaveLength(1);
  });

  it('bỏ qua hoàn toàn khi không phải HTTP (socket, cron)', async () => {
    const wsContext = { getType: () => 'ws' } as any;
    await new Promise<void>(resolve => {
      interceptor
        .intercept(wsContext, { handle: () => of('ok') } as any)
        .subscribe({ next: () => resolve() });
    });

    expect(recorded).toHaveLength(0);
  });
});
