import React from "react";

interface Props {
  children: React.ReactNode;
}

/**
 * "Nothing here", said the same way on every Confession page.
 *
 * A dashed box rather than a line of grey text in the middle of a table: it
 * reads as a place where things WILL appear, which is the difference between an
 * empty list and a broken one.
 */
const CommunityEmpty: React.FC<Props> = ({ children }) => (
  <div className="rounded-2xl border border-dashed border-gray-300 py-12 text-center text-sm text-gray-500">
    {children}
  </div>
);

export default CommunityEmpty;
