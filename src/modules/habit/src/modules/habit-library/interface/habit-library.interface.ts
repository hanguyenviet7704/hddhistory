import { Types } from 'mongoose';

import { ITranslation } from '@utils/interface/common.interface';

import { HabitLibraryStatus } from '../enum/habit-library.enum';

export interface IHabitLibrary {
  title: ITranslation;
  skillsetId: Types.ObjectId | string;
  status: HabitLibraryStatus;
  image?: string;
  /**
   * What the habit is, concretely, and when it applies — 1–2 sentences per
   * locale. Grounds the Coach's practice scenes; without it a short title is
   * all the model has and the scenes drift.
   */
  description?: ITranslation | null;
  /**
   * Moments the habit typically comes up, one per line per locale ("khi họp
   * nhóm bị bác ý"). Each scene in the Coach's pool stands in one of them.
   */
  contexts?: ITranslation | null;
  /**
   * The skill's rubric — the 4–5 things a good answer to this habit's scenes
   * does. One entry per criterion, one criterion per line per locale, in the
   * form `key | label`:
   *
   *     clarity | Nói rõ mình không muốn hay không thể
   *     boundary | Giữ ranh giới khi bị gây áp lực
   *
   * The `key` is what makes scores comparable: the skill number on the habit is
   * an average over the SAME criteria across many scenes, so a renamed label
   * must not orphan a reader's history. Absent = this habit's scenes are
   * practised but not scored.
   */
  rubric?: ITranslation | null;
  /**
   * The skill's own difficulty ladder — what level 1..5 MEANS for this habit,
   * one rung per line per locale in the form `<level> | <situation shape>`:
   *
   *     1 | Nhận ra thôi thúc khi chưa có gì cản
   *     4 | Đối phương kích thêm lần thứ hai
   *
   * Levels used to mean only "more pressure", which produced the same five
   * shapes for every skill. A listening habit escalates nothing like a rest
   * habit; the ladder is where that difference is written down, and generation
   * builds a scene from the rung its slot lands on. Absent = generic pressure.
   */
  ladder?: ITranslation | null;
  defaultReminderTime?: string;
  order: number;
  keypointIds?: (Types.ObjectId | string)[];
}
