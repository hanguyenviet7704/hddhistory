import React from "react";
import {
  ArrowRightOnRectangleIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  InboxIcon,
  QuestionMarkCircleIcon,
} from "@heroicons/react/24/outline";

import DashboardShell from "../../components/dashboard/DashboardShell";
import StatCard, { DeltaBadge } from "../../components/dashboard/StatCard";
import {
  formatNumber,
  formatPercent,
} from "../../components/dashboard/dashboardTheme";
import {
  useDashboardData,
  useDashboardFilters,
} from "../../components/dashboard/useDashboard";
import { dashboardService } from "../../services/dashboardService";
import CoachMetricsBlock from "./components/CoachMetricsBlock";
import {
  BreakdownList,
  FunnelRow,
  OutcomeTable,
  SectionCard,
  StatsPair,
} from "./components/CoachStatsWidgets";

/** Two ranked lists side by side — the shape half this page takes. */
const Pair: React.FC<{
  left: { title: string; hint?: string; node: React.ReactNode };
  right: { title: string; hint?: string; node: React.ReactNode };
}> = ({ left, right }) => (
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    {[left, right].map((side) => (
      <div key={side.title}>
        <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
          {side.title}
        </h3>
        {side.hint && (
          <p className="mt-0.5 text-xs text-gray-500">{side.hint}</p>
        )}
        <div className="mt-2">{side.node}</div>
      </div>
    ))}
  </div>
);

/**
 * What the page says when the app reported nothing for this range.
 *
 * Its own notice rather than `DashboardShell`'s empty state, because block ⑤
 * below it is NOT empty — those counters come from the server and do not depend
 * on which build somebody has installed. Blanking the whole page would hide the
 * only numbers there are.
 */
const EmptyEventStream: React.FC<{ appEnv: string }> = ({ appEnv }) => (
  <div className="rounded-xl border border-gray-200 bg-white p-8 text-center">
    <InboxIcon className="mx-auto h-8 w-8 text-gray-400" />
    <p className="mt-2 font-medium text-gray-800">
      Kỳ này chưa có event Coach nào
    </p>
    <p className="mx-auto mt-1 max-w-2xl text-sm text-gray-500">
      Không có sự kiện <code className="text-gray-600">coach_*</code> nào ở môi
      trường <span className="font-medium">{appEnv}</span> trong khoảng đã chọn.
      Trang này đọc tracking do app bắn lên, nên chỉ thấy được những bản app đã
      mang tracking Coach theo — một môi trường mà mọi người còn dùng bản cũ hơn
      sẽ trống dù Coach vẫn đang chạy. Thử đổi môi trường, hoặc nới khoảng ngày.
      Bộ đếm server ở khối ⑤ bên dưới đếm ở phía server nên không phụ thuộc
      chuyện này.
    </p>
  </div>
);

/**
 * AI Coach, measured.
 *
 * Reads the app's event stream (`user_events`) rather than the Coach's own
 * collections, because the questions this page answers are about what happened
 * on the DEVICE — a bubble somebody ignored, a sheet that opened onto silence,
 * a session killed with the app. The server never sees those.
 *
 * One caveat worth knowing before reading a zero here: Coach tracking landed on
 * `develop` on 2026-09-04 and is not in a production build yet, so `prod` will
 * be empty until a release carries it. Block ⑤ is the exception — those
 * counters are written server-side and do not depend on the installed app.
 */
const CoachStatsPage: React.FC = () => {
  const { filters, setFilters, applyPreset, activePreset, query } =
    useDashboardFilters();
  const { data, loading, error, reload } = useDashboardData(
    dashboardService.getCoach,
    query,
  );

  const ending = data?.ending;
  const doors = data?.doors;
  const inSession = data?.inSession;
  const surfaces = data?.surfaces;

  return (
    <DashboardShell
      title="Thống kê AI Coach"
      subtitle="Người đọc vào Coach qua cửa nào, làm gì trong phiên, và phiên kết thúc ra sao."
      filters={filters}
      activePreset={activePreset}
      onPreset={applyPreset}
      onChange={setFilters}
      range={data?.range}
      compareRange={data?.compareRange}
      loading={loading}
      error={error}
      hasData={Boolean(data)}
      onReload={reload}
    >
      {data && ending && doors && inSession && surfaces && (
        <div className="space-y-4">
          {!data.hasData && <EmptyEventStream appEnv={filters.appEnv} />}

          {data.hasData && (
            <>
              {/* The three numbers the page exists for, before any breakdown. */}
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <StatCard
                  label="Mở phiên"
                  value={formatNumber(ending.opened)}
                  hint={
                    ending.reopened
                      ? `Đã trừ ${formatNumber(
                          ending.reopened,
                        )} lượt tự mở lại sau 48h`
                      : "Lượt người đọc chủ động mở Coach"
                  }
                  delta={
                    <DeltaBadge
                      current={ending.opened}
                      previous={ending.previous?.opened}
                    />
                  }
                />
                <StatCard
                  label="Đi hết đường"
                  value={formatNumber(ending.completed)}
                  hint="Server khép phiên, không phải người đọc tự đóng"
                  icon={<CheckCircleIcon className="h-5 w-5" />}
                  delta={
                    <DeltaBadge
                      current={ending.completed}
                      previous={ending.previous?.completed}
                    />
                  }
                />
                <StatCard
                  label="Bỏ giữa chừng"
                  value={formatNumber(ending.abandoned)}
                  hint="Đóng sheet khi phiên chưa khép"
                  icon={<ArrowRightOnRectangleIcon className="h-5 w-5" />}
                  delta={
                    <DeltaBadge
                      current={ending.abandoned}
                      previous={ending.previous?.abandoned}
                      invert
                    />
                  }
                />
                <StatCard
                  label="Tỉ lệ hoàn thành"
                  value={formatPercent(ending.completionRate)}
                  hint={`Trên ${formatNumber(
                    ending.exits,
                  )} phiên có ghi nhận kết thúc`}
                />
              </div>

              {ending.unaccounted > 0 && (
                <p className="flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800">
                  <QuestionMarkCircleIcon className="mt-0.5 h-4 w-4 shrink-0" />
                  <span>
                    {formatNumber(ending.unaccounted)} phiên mở ra rồi không báo
                    về lúc kết thúc — app bị kill, mất mạng, hoặc phiên kéo qua
                    ngoài khoảng đang xem. Không tính vào "bỏ giữa chừng": đoán
                    bừa sẽ làm tỉ lệ hoàn thành thành một con số bịa.
                  </span>
                </p>
              )}

              <SectionCard
                index="①"
                title="Cửa vào"
                description="Hai đường vào Coach. Tỉ lệ tính trên số NGƯỜI khác nhau, không phải số lượt: một người thấy bong bóng chục lần mỗi ngày, đếm lượt thì chỉ đo được shell dựng lại bao nhiêu lần."
              >
                <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                  <div>
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Bong bóng trên shell
                    </h3>
                    <ol className="mt-3 space-y-3">
                      {doors.bubble.map((step) => (
                        <FunnelRow
                          key={step.event}
                          step={step}
                          first={doors.bubble[0]?.users ?? 0}
                        />
                      ))}
                    </ol>
                  </div>
                  <div>
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Màn mời sau keypoint
                    </h3>
                    <ol className="mt-3 space-y-3">
                      {doors.invite.map((step) => (
                        <FunnelRow
                          key={step.event}
                          step={step}
                          first={doors.invite[0]?.users ?? 0}
                        />
                      ))}
                    </ol>
                  </div>
                </div>

                <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-3">
                  {doors.misses.map((miss) => (
                    <div
                      key={miss.key}
                      className="rounded-lg border border-gray-100 bg-gray-50 px-3 py-2"
                    >
                      <p className="text-xs font-medium text-gray-500">
                        {miss.label}
                      </p>
                      <p className="mt-0.5 text-lg font-semibold tabular-nums text-gray-900">
                        {formatNumber(miss.events)}
                        <span className="ml-1.5 text-xs font-normal text-gray-500">
                          {formatNumber(miss.users)} người
                        </span>
                      </p>
                      {miss.hint && (
                        <p className="mt-0.5 text-[11px] text-gray-500">
                          {miss.hint}
                        </p>
                      )}
                    </div>
                  ))}
                </div>

                <div className="mt-4">
                  <Pair
                    left={{
                      title: "Phiên mở được, theo cửa",
                      hint: "Đã loại các lượt tự mở lại sau 48h.",
                      node: <BreakdownList rows={doors.byEntry} />,
                    }}
                    right={{
                      title: "Vì sao cửa mở ra sự im lặng",
                      hint: "Bấm vào nhưng server không có gì để nói.",
                      node: (
                        <BreakdownList
                          rows={doors.silentReasons}
                          emptyText="Không có lượt nào mở ra sự im lặng"
                        />
                      ),
                    }}
                  />
                </div>
              </SectionCard>

              <SectionCard
                index="②"
                title="Trong phiên"
                description="Người đọc làm gì khi đã vào, và có bao nhiêu lượt gửi không tới nơi."
              >
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <StatCard
                    label="Lượt gửi"
                    value={formatNumber(inSession.turns.events)}
                    hint={`${formatNumber(inSession.turns.users)} người`}
                  />
                  <StatCard
                    label="Lượt gửi hỏng"
                    value={formatNumber(inSession.failed.events)}
                    hint="Bấm gửi và không nhận lại được gì"
                    icon={<ExclamationTriangleIcon className="h-5 w-5" />}
                  />
                  <StatCard
                    label="Tỉ lệ hỏng"
                    value={formatPercent(inSession.failureRate)}
                    hint="Trên tổng số lần thử gửi, kể cả lần hỏng"
                  />
                  <StatCard
                    label="Phiên hết hạn giữa chừng"
                    value={formatNumber(inSession.expired.events)}
                    hint="Đang gõ dở thì phiên quá 48h"
                  />
                </div>

                <div className="mt-4">
                  <Pair
                    left={{
                      title: "Người đọc làm gì",
                      hint: "Theo kiểu của lượt gửi.",
                      node: <BreakdownList rows={inSession.byKind} />,
                    }}
                    right={{
                      title: "Đóng sheet ở chặng nào",
                      hint: "Chặng mà phiên đang đứng lúc đóng — kể cả phiên đi hết đường.",
                      node: <BreakdownList rows={inSession.exitStep} />,
                    }}
                  />
                </div>

                {inSession.errorTypes.length > 0 && (
                  <div className="mt-4">
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Lượt gửi hỏng vì lỗi gì
                    </h3>
                    <div className="mt-2">
                      <BreakdownList
                        rows={inSession.errorTypes}
                        color="#e11d48"
                      />
                    </div>
                  </div>
                )}
              </SectionCard>

              <SectionCard
                index="③"
                title="Kết thúc phiên"
                description="Phiên khép lại thế nào, kéo dài bao lâu, và lời níu khi đóng giữa chừng có giữ được ai không."
              >
                <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
                  <StatsPair
                    title="Số lượt trong một phiên"
                    completed={ending.turnCount.completed}
                    abandoned={ending.turnCount.abandoned}
                  />
                  <StatsPair
                    title="Thời lượng một phiên"
                    completed={ending.durationSec.completed}
                    abandoned={ending.durationSec.abandoned}
                    asDuration
                  />
                </div>

                <div className="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
                  <div>
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Cửa nào dẫn tới đi hết đường
                    </h3>
                    <div className="mt-2">
                      <OutcomeTable rows={ending.byEntry} />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Lời níu khi bấm đóng
                    </h3>
                    <p className="mt-0.5 text-xs text-gray-500">
                      Tỉ lệ ở lại tính trên số người TRẢ LỜI lời níu — ai lướt
                      qua nó thì không chứng minh điều gì.
                    </p>
                    <div className="mt-2 grid grid-cols-3 gap-2">
                      {[
                        { label: "Hiện lời níu", value: ending.plea.shown },
                        { label: "Ở lại", value: ending.plea.stay },
                        { label: "Vẫn đóng", value: ending.plea.leave },
                      ].map((cell) => (
                        <div
                          key={cell.label}
                          className="rounded-lg border border-gray-100 bg-gray-50 px-3 py-2"
                        >
                          <p className="text-xs text-gray-500">{cell.label}</p>
                          <p className="mt-0.5 text-lg font-semibold tabular-nums text-gray-900">
                            {formatNumber(cell.value)}
                          </p>
                        </div>
                      ))}
                    </div>
                    <p className="mt-2 text-sm text-gray-700">
                      Níu lại được{" "}
                      <span className="font-semibold">
                        {formatPercent(ending.plea.stayRate)}
                      </span>
                    </p>
                  </div>
                </div>

                <p className="mt-4 text-xs text-gray-500">
                  Trong kỳ có {formatNumber(ending.resumed)} lượt mở tiếp một
                  phiên đang dở và {formatNumber(ending.reopened)} lượt tự mở
                  lại sau khi phiên hết hạn 48h.
                </p>
              </SectionCard>

              <SectionCard
                index="④"
                title="Bề mặt & chất lượng"
                description="Những thứ Coach đưa ra giữa phiên, và người đọc chấm lại thế nào."
              >
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-7">
                  {surfaces.items.map((item) => (
                    <div
                      key={item.key}
                      className="rounded-lg border border-gray-100 bg-gray-50 px-3 py-2"
                    >
                      <p className="text-xs text-gray-500">{item.label}</p>
                      <p className="mt-0.5 text-lg font-semibold tabular-nums text-gray-900">
                        {formatNumber(item.events)}
                      </p>
                      <p className="text-[11px] text-gray-500">
                        {formatNumber(item.users)} người
                      </p>
                    </div>
                  ))}
                </div>

                <div className="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
                  <div>
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Đánh giá cuối phiên
                    </h3>
                    <p className="mt-0.5 text-xs text-gray-500">
                      👍 chiếm{" "}
                      <span className="font-semibold text-gray-700">
                        {formatPercent(surfaces.rating.thumbsUpRate)}
                      </span>{" "}
                      số lượt có chấm.
                    </p>
                    <div className="mt-2">
                      <BreakdownList
                        rows={surfaces.rating.thumbs}
                        emptyText="Chưa ai chấm trong kỳ"
                      />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Lý do đằng sau 👎
                    </h3>
                    <p className="mt-0.5 text-xs text-gray-500">
                      5 chip cố định do app đặt sẵn — không phải chữ người đọc
                      gõ.
                    </p>
                    <div className="mt-2">
                      <BreakdownList
                        rows={surfaces.rating.chips}
                        color="#e11d48"
                        emptyText="Chưa có lượt 👎 nào kèm lý do"
                      />
                    </div>
                  </div>
                </div>

                <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <div className="rounded-lg border border-gray-100 bg-gray-50 px-3 py-2">
                    <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Quiz trong phiên
                    </p>
                    <p className="mt-1 text-sm text-gray-700">
                      {formatNumber(surfaces.quiz.runs)} lượt chạy ·{" "}
                      {formatNumber(surfaces.quiz.questions)} câu · đúng{" "}
                      <span className="font-semibold">
                        {formatPercent(surfaces.quiz.passRate)}
                      </span>
                    </p>
                  </div>
                  <div className="rounded-lg border border-gray-100 bg-gray-50 px-3 py-2">
                    <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      Mic
                    </p>
                    <p className="mt-1 text-sm text-gray-700">
                      {formatNumber(surfaces.mic.starts)} lượt bấm · cho phép{" "}
                      <span className="font-semibold">
                        {formatPercent(surfaces.mic.grantRate)}
                      </span>{" "}
                      · {formatNumber(surfaces.mic.done)} lượt xong, ra chữ{" "}
                      <span className="font-semibold">
                        {formatPercent(surfaces.mic.textRate)}
                      </span>
                    </p>
                  </div>
                </div>
              </SectionCard>
            </>
          )}

          {/* Outside the gate on purpose: these counters are written
              server-side, so they have data even in a range where the app
              never reported a single event. */}
          <CoachMetricsBlock />
        </div>
      )}
    </DashboardShell>
  );
};

export default CoachStatsPage;
