import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Request } from 'express';
import { Observable, tap } from 'rxjs';

import { redactBody, safeStringify } from '@utils/redact.util';
import { UserRole } from 'src/modules/user/src/modules/auth/enum/user.enum';
import { IUser } from 'src/modules/user/src/modules/auth/interface/user.interface';

import { AdminAuditService, serverDateOf } from './admin-audit.service';

/** Chỉ thao tác GHI mới vào sổ — đọc thì không ai cần biết ai đã đọc. */
const WRITE_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

/**
 * Trần độ dài của nội dung lưu lại.
 *
 * Một lần đăng cấu hình paywall là vài chục nghìn ký tự. Giữ nguyên thì bảng
 * nhật ký to hơn bảng dữ liệu nó ghi chép, mà phần vượt quá chừng này thì
 * người đọc cũng không đọc trong một ô bảng. Bị cắt thì có cờ riêng, để giao
 * diện nói thẳng là chưa đủ chứ không giả vờ là đủ.
 */
const BODY_MAX_CHARS = 8_000;

const ERROR_MAX_CHARS = 500;

/**
 * Header trang quản trị tự gắn lên mọi request của nó.
 *
 * Đây là thứ phân biệt "người vận hành" với "người dùng app", chứ KHÔNG phải
 * vai trò. Vai trò không làm được việc đó ở hệ này: tài khoản đang dùng panel
 * mang `role: USER` trong database, nên lọc theo vai trò cho ra một nhật ký
 * trống trơn — đúng thứ đã xảy ra.
 *
 * Nó do client gửi lên, nên về lý là giả được. Nhưng mọi endpoint admin ở đây
 * vốn chỉ có `AuthGuard` và KHÔNG có chốt vai trò nào — bất kỳ token nào cũng
 * gọi được chúng. Nên cái header này không nới thêm quyền gì; nó chỉ quyết
 * định dòng nào vào sổ.
 */
const ADMIN_PANEL_HEADER = 'x-admin-panel';

interface AuthenticatedRequest extends Request {
  user?: IUser;
}

/**
 * Ghi lại mọi thao tác GHI của một tài khoản ADMIN.
 *
 * Toàn cục và tự động, chứ không phải mỗi controller tự gọi. Một nhật ký phải
 * được nhớ gọi ở hai trăm chỗ là một nhật ký sẽ thiếu đúng chỗ người ta cần
 * tra, và mọi endpoint viết sau này đều bắt đầu bằng việc quên nó.
 *
 * Lọc theo VAI TRÒ, không theo đường dẫn. Cùng một API phục vụ cả app, nên lọc
 * bằng tiền tố đường dẫn sẽ vừa sót (nhiều endpoint admin không có tiền tố
 * `admin/`) vừa thừa. `role === ADMIN` thì chính xác và không cần bảo trì.
 *
 * Đọc `req.user` THẲNG từ ExecutionContext, không tiêm `RequestService`: nó là
 * `Scope.REQUEST`, mà Nest đẩy scope ấy ngược lên toàn bộ đồ thị phụ thuộc —
 * repo này đã dính hai lần và cả hai vết còn comment lại
 * (`notification-campaign.service.ts`, `week-recap.service.ts`). Một
 * interceptor toàn cục request-scope sẽ kéo theo cả ứng dụng.
 */
@Injectable()
export class AdminAuditInterceptor implements NestInterceptor {
  constructor(private readonly audit: AdminAuditService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

    const http = context.switchToHttp();
    const request = http.getRequest<AuthenticatedRequest>();

    if (!WRITE_METHODS.has(request.method)) return next.handle();

    const user = request.user;
    if (!user) return next.handle();

    /**
     * Token cũ không mang `role`, nên không phân biệt được ai.
     *
     * `AuthGuard` gán thẳng payload JWT vào `req.user`, và payload ấy chỉ có
     * `role` từ 2026-09-17 — token ký trước đó sống thêm bảy ngày nữa. Trong
     * khoảng đó thao tác của admin KHÔNG vào sổ được, và cái đáng sợ là nó im
     * lặng: đó chính là cách lỗi này lọt qua lần đầu, một trang nhật ký trống
     * trơn mà không có gì để lần.
     *
     * Nên nó phải kêu. Có tiết chế, vì token của mọi người dùng app cũng thiếu
     * `role` cho tới khi họ làm mới.
     */
    // Hoặc panel tự khai, hoặc tài khoản thật sự được đánh dấu ADMIN. Giữ cả
    // hai: dấu hiệu từ panel là thứ chạy được HÔM NAY, còn vai trò là thứ đúng
    // khi các tài khoản vận hành được đánh dấu cho tử tế.
    const fromPanel = request.headers?.[ADMIN_PANEL_HEADER] !== undefined;
    if (!fromPanel && user.role !== UserRole.ADMIN) return next.handle();

    const startedAt = Date.now();
    const snapshot = this.describe(request, user);

    return next.handle().pipe(
      tap({
        next: () =>
          this.write(snapshot, {
            statusCode: http.getResponse()?.statusCode ?? 200,
            ok: true,
            durationMs: Date.now() - startedAt,
          }),
        // Thất bại cũng vào sổ. "Ai đã THỬ xoá cái này" là một câu hỏi thật, và
        // một thao tác hỏng thường là thứ người ta đi tìm trước tiên.
        error: (error: any) =>
          this.write(snapshot, {
            statusCode: error?.status ?? error?.statusCode ?? 500,
            ok: false,
            durationMs: Date.now() - startedAt,
            errorMessage: String(error?.message ?? '').slice(0, ERROR_MAX_CHARS),
          }),
      }),
    );
  }

  private describe(request: AuthenticatedRequest, user: IUser) {
    const serialized = safeStringify(redactBody(request.body));
    const truncated = serialized.length > BODY_MAX_CHARS;

    return {
      actorId: String(user.id ?? user._id ?? ''),
      actorEmail: user.email ?? '',
      actorName: user.name ?? '',
      method: request.method,
      // `originalUrl` chứ không phải `url`: `url` đã bị Nest cắt mất tiền tố.
      // Bỏ query string — nó không phải thao tác, và hay mang theo token.
      path: (request.originalUrl ?? '').split('?')[0],
      route: request.route?.path ?? '',
      body: truncated ? serialized.slice(0, BODY_MAX_CHARS) : serialized,
      bodyTruncated: truncated,
      serverDate: serverDateOf(new Date()),
    };
  }

  /**
   * Không await, và mọi lỗi đều đã bị nuốt ở tầng repository.
   *
   * Thao tác đã chạy xong và câu trả lời đã trên đường về người dùng lúc hàm
   * này chạy. Nó không được phép làm chậm, và càng không được phép làm hỏng.
   */
  private write(
    snapshot: Record<string, unknown>,
    outcome: {
      statusCode: number;
      ok: boolean;
      durationMs: number;
      errorMessage?: string;
    },
  ): void {
    this.audit.record({ ...snapshot, errorMessage: '', ...outcome } as never);
  }
}
