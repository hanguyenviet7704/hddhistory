import React from "react";
import { UserRoundIcon } from "lucide-react";

import {
  CommunityAuthorType,
  ICommunityAuthor,
} from "../../types/interface/community.interface";

/**
 * The author's face, drawn exactly as the app draws it.
 *
 * The tints, the inks and the slot arithmetic are copied from the Flutter
 * `CommunityAvatar` on purpose: a moderator scanning this list and a reader
 * scrolling the feed have to be looking at the SAME person. A different palette
 * here would mean the panel and the phone disagree about who wrote what, which
 * is exactly the thing a moderator is trying to keep track of.
 */
const TINTS = ["#E6F1F0", "#FBE4EC", "#F0EDE4", "#FBE4DC", "#E7EEFC"];
const INKS = ["#2F7370", "#C2417B", "#8A7434", "#C2632F", "#3A63B8"];

const slotFor = (name: string) => {
  if (!name) return 0;
  let sum = 0;
  for (let i = 0; i < name.length; i += 1) sum += name.charCodeAt(i);

  return sum % TINTS.length;
};

const initialsFor = (name: string) =>
  name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");

interface Props {
  author?: ICommunityAuthor | null;
  size?: number;
}

const CommunityAvatarDisc: React.FC<Props> = ({ author, size = 38 }) => {
  const style = { width: size, height: size };
  const type = author?.authorType;

  if (author?.avatar) {
    return (
      <img
        src={author.avatar}
        alt={author.name}
        style={style}
        className="shrink-0 rounded-full object-cover"
      />
    );
  }

  // Anonymous carries no name and no id to derive anything FROM, and that is
  // the point: two anonymous posts must not look like they came from the same
  // person, nor from different ones.
  if (type === CommunityAuthorType.ANONYMOUS) {
    return (
      <div
        style={style}
        className="flex shrink-0 items-center justify-center rounded-full bg-gray-100 text-gray-400"
      >
        <UserRoundIcon size={size * 0.55} />
      </div>
    );
  }

  if (type === CommunityAuthorType.OFFICIAL) {
    return (
      <div
        style={{ ...style, background: "#EBEAFD", color: "#4B44CA" }}
        className="flex shrink-0 items-center justify-center rounded-full text-sm font-bold"
      >
        M
      </div>
    );
  }

  const slot = slotFor(author?.name ?? "");

  return (
    <div
      style={{ ...style, background: TINTS[slot], color: INKS[slot] }}
      className="flex shrink-0 items-center justify-center rounded-full text-xs font-bold"
    >
      {initialsFor(author?.name ?? "")}
    </div>
  );
};

export default CommunityAvatarDisc;
