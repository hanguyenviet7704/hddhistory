# Week recap artwork

One file, all locales: `wrap_bg.jpg`, **1890x3360** (9:16), JPEG q95 (~1MB; the
source PNG is 6MB and five locales of that was the reason to re-encode).

The stripped art (2026-08-20) carries **no text at all** — no title, no month or
dates, and none of the fixed labels either. Everything readable on the poster is
drawn by `WeekRecapPoster` from l10n, which is why one artwork now serves all
five locales and a copy change never means new art.

What the image still owns: the paper collage, the empty notepad/bubble/polaroid/
stamps/ruled sheet, the quote's red underline, and the calendar card's CHROME —
chevrons, divider rule, seven empty cell boxes. `WeekRecapCalendar` positions
its rows onto that chrome by card-relative fractions; every other label sits in
`week_recap_poster_slots.dart` as fractions of the poster box, measured against
this artwork. Re-cutting the collage means re-measuring both.

Still owed by the designer: the brush-script display face for `Tuần NN` (the
title currently renders in Lumios Marker, the closest hand in the bundle).
