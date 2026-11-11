import React from "react";

interface Props {
  title: string;
  subtitle?: string;
  /** Filters and the page's primary action, right-aligned. */
  children?: React.ReactNode;
}

/**
 * The heading every Confession page wears.
 *
 * Extracted because the five pages had five near-identical copies that had
 * already started drifting — different gaps, one with the search box above the
 * title. Five pages of one feature should read as one product, and the cheapest
 * way to keep that true is for there to be only one place the heading exists.
 */
const CommunityPageHeader: React.FC<Props> = ({ title, subtitle, children }) => (
  <div className="flex flex-wrap items-start justify-between gap-4">
    <div>
      <h1 className="text-2xl font-semibold text-gray-900">{title}</h1>
      {!!subtitle && (
        <p className="mt-0.5 max-w-2xl text-sm text-gray-500">{subtitle}</p>
      )}
    </div>
    {!!children && (
      <div className="flex flex-wrap items-center gap-2">{children}</div>
    )}
  </div>
);

export default CommunityPageHeader;
