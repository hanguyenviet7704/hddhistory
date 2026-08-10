import React, { useCallback, useEffect, useState } from "react";
import { ArrowLeftIcon } from "@heroicons/react/24/outline";
import { Link, useParams } from "react-router-dom";

import { learningImportService } from "../../services/learningImportService";
import { ILearningImportDetail } from "../../types/interface/learningImport.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import {
  ERROR_LABELS,
  formatDateTime,
  formatDuration,
  formatVnd,
  SourceBadge,
  StatusBadge,
} from "./learningImportLabels";

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="text-xs uppercase tracking-wide text-gray-500">
        {label}
      </div>
      <div className="mt-1 text-sm text-gray-900">{children}</div>
    </div>
  );
}

/**
 * One import, plus the full lesson it produced.
 *
 * The lesson body is the reason this page exists. Prompt quality is not
 * something a status column can show — you have to read a few real lessons to
 * know whether the sections are balanced, whether it padded, whether it drifted
 * off the source. Everything else here is context for that judgement.
 */
export default function LearningImportDetail() {
  const { jobId } = useParams<{ jobId: string }>();
  const { showError } = useNotification();

  const [detail, setDetail] = useState<ILearningImportDetail | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchDetail = useCallback(async () => {
    if (!jobId) return;
    setLoading(true);
    try {
      setDetail(await learningImportService.getImportDetail(jobId));
    } catch (error: any) {
      console.error("Failed to fetch import detail", error);
      showError("Failed to load this import");
    } finally {
      setLoading(false);
    }
  }, [jobId, showError]);

  useEffect(() => {
    fetchDetail();
  }, [fetchDetail]);

  if (loading) {
    return <div className="p-10 text-center text-sm text-gray-500">Loading…</div>;
  }

  if (!detail) {
    return (
      <div className="p-10 text-center text-sm text-gray-500">
        This import no longer exists.
      </div>
    );
  }

  const { source, usage, lesson } = detail;

  return (
    <div className="p-6">
      <Link
        to="/learning-imports"
        className="mb-4 inline-flex items-center gap-1 text-sm font-semibold text-indigo-600 hover:text-indigo-800"
      >
        <ArrowLeftIcon className="h-4 w-4" />
        Back to imports
      </Link>

      <div className="mb-6 flex items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <SourceBadge type={detail.sourceType} />
            <h1 className="text-2xl font-bold text-gray-900">
              {detail.sourceLabel || "(unnamed source)"}
            </h1>
          </div>
          <p className="mt-1 font-mono text-xs text-gray-500">
            job {detail.id} · user {detail.userId}
          </p>
        </div>
        <StatusBadge status={detail.status} />
      </div>

      <div className="mb-6 grid grid-cols-2 gap-6 rounded-xl border border-gray-200 bg-white p-5 md:grid-cols-4">
        <Field label="Output language">
          <span className="uppercase">{detail.outputLocale}</span>
        </Field>
        <Field label="Created">{formatDateTime(detail.createdAt)}</Field>
        <Field label="Started">{formatDateTime(detail.startedAt)}</Field>
        <Field label="Finished">{formatDateTime(detail.completedAt)}</Field>

        {source?.type === "youtube" ? (
          <>
            <Field label="Video">
              {source.url ? (
                <a
                  href={source.url}
                  target="_blank"
                  rel="noreferrer"
                  className="text-indigo-600 hover:text-indigo-800"
                >
                  Open on YouTube
                </a>
              ) : (
                "—"
              )}
            </Field>
            <Field label="Duration">
              {formatDuration(source.videoDurationSeconds)}
            </Field>
          </>
        ) : (
          <>
            {/* Filename only. The uploaded document itself is deliberately not
                reachable from here — the panel is for judging output quality,
                not for reading users' private material. */}
            <Field label="File">{source?.fileName || "—"}</Field>
            <Field label="Pages">{source?.pageCount ?? "—"}</Field>
          </>
        )}

        <Field label="Tokens">
          {usage ? `${usage.inputTokens} in / ${usage.outputTokens} out` : "—"}
        </Field>
        <Field label="Estimated cost">
          {formatVnd(usage?.estimatedCostVnd)}
        </Field>
      </div>

      {detail.errorCode && (
        <div className="mb-6 rounded-xl border border-rose-200 bg-rose-50 p-5">
          <div className="font-semibold text-rose-800">
            {ERROR_LABELS[detail.errorCode] ?? detail.errorCode}
          </div>
          <div className="mt-1 font-mono text-xs text-rose-700">
            {detail.errorCode}
          </div>
          {detail.errorMessage && (
            <p className="mt-2 text-sm text-rose-700">{detail.errorMessage}</p>
          )}
          <p className="mt-3 text-xs text-rose-600">
            Failed imports do not consume the user's monthly quota.
          </p>
        </div>
      )}

      <div className="rounded-xl border border-gray-200 bg-white">
        <div className="flex items-baseline justify-between border-b border-gray-200 px-5 py-4">
          <h2 className="text-lg font-semibold text-gray-900">
            Generated lesson
          </h2>
          {lesson && (
            <span className="text-xs text-gray-500">
              {lesson.sections.length} sections · {lesson.wordCount} words ·{" "}
              {lesson.estimatedMinutes} min read
            </span>
          )}
        </div>

        {!lesson ? (
          <div className="p-10 text-center text-sm text-gray-500">
            {detail.status === "completed"
              ? "The lesson was generated but has since been deleted by the user."
              : "No lesson was produced by this run."}
          </div>
        ) : (
          <div className="px-5 py-6">
            <h3 className="text-xl font-bold text-gray-900">{lesson.title}</h3>
            {lesson.description && (
              <p className="mt-1 text-sm text-gray-600">{lesson.description}</p>
            )}

            {lesson.sections.map((section, sectionIndex) => (
              <section
                key={sectionIndex}
                className="mt-8 border-t border-gray-100 pt-6 first:border-0"
              >
                <div className="text-xs uppercase tracking-wide text-gray-400">
                  Section {sectionIndex + 1}
                </div>
                <h4 className="mt-1 text-lg font-semibold text-gray-900">
                  {section.title}
                </h4>

                {section.blocks.map((block, blockIndex) =>
                  block.type === "heading" ? (
                    <h5
                      key={blockIndex}
                      className="mt-4 font-semibold text-gray-800"
                    >
                      {block.text}
                    </h5>
                  ) : (
                    <p
                      key={blockIndex}
                      className="mt-3 leading-relaxed text-gray-700"
                    >
                      {block.text}
                    </p>
                  ),
                )}
              </section>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
