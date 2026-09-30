import { Injectable } from '@nestjs/common';

import { RequestService } from '@base/service/request.service';
import { IResponseListPage } from '@utils/interface/paging/page.interface';

import { GetSavedCardsDto, SaveCardDto } from './dto/saved-card.dto';
import { SavedCardRepository } from './saved-card.repository';
import { CourseRepository } from '../course/repository/course.repository';
import { ContentSource } from '../course-version/content-source.service';
import { KeypointRepository } from '../keypoint/repository/keypoint.repository';

@Injectable()
export class SavedCardService {
  constructor(
    private readonly savedCardRepository: SavedCardRepository,
    private readonly keypointRepository: KeypointRepository,
    private readonly courseRepository: CourseRepository,
    private readonly contentSource: ContentSource,
    private readonly requestService: RequestService,
  ) {}

  async save(userId: string, dto: SaveCardDto): Promise<void> {
    await this.savedCardRepository.save(userId, dto);
  }

  async remove(userId: string, keypointId: string): Promise<void> {
    await this.savedCardRepository.remove(userId, keypointId);
  }

  /** Ids only — fills the bookmark's filled/hollow state on the recap card. */
  async getSavedIds(userId: string): Promise<string[]> {
    return this.savedCardRepository.findKeypointIds(userId);
  }

  /**
   * The Saved cards grid / deck.
   *
   * Only `recapText` comes from the saved row. Title, image and course title
   * are re-read from the catalogue on every request so a card follows the
   * reader's app language and picks up authoring fixes — the bookmark stores an
   * id, not a copy of the course.
   *
   * A card whose keypoint no longer resolves (unpublished, deleted) is dropped
   * rather than rendered blank, the same answer `recently-viewed` gives.
   */
  async getSaved(
    userId: string,
    dto: GetSavedCardsDto,
  ): Promise<IResponseListPage<any>> {
    const page = await this.savedCardRepository.paginateForUser(
      userId,
      dto.page,
      dto.take,
    );
    if (!page.items.length) return { ...page, items: [] };

    const keypointIds = page.items.map(item => item.keypointId);
    const courseIds = Array.from(
      new Set(page.items.map(item => item.courseId).filter(Boolean)),
    );

    const [keypoints, courses] = await Promise.all([
      // Thẻ đã lưu trải nhiều khoá, mỗi khoá có thể ở tag khác nhau -- đọc
      // mỗi keypoint từ đúng bản của nó. Keypoint bị bỏ khỏi tag hiện tại sẽ
      // không có trong kết quả, và dòng `if (!keypoint) return null` dưới đây
      // vốn đã rụng thẻ đó êm.
      this.contentSource.getKeypointBriefsAcrossVersions(
        keypointIds,
        this.requestService.headers,
      ),
      this.courseRepository.findBriefByIds(courseIds),
    ]);

    const keypointById = new Map(
      keypoints.map((keypoint: any) => [keypoint._id.toString(), keypoint]),
    );
    const courseById = new Map(
      courses.map((course: any) => [course._id.toString(), course]),
    );

    const items = page.items
      .map((item: any) => {
        const keypoint = keypointById.get(item.keypointId);
        if (!keypoint) return null;

        const course = item.courseId
          ? courseById.get(item.courseId)
          : undefined;

        return {
          _id: item._id,
          keypointId: item.keypointId,
          lessonId: item.lessonId ?? '',
          courseId: item.courseId ?? '',
          title: keypoint.title ?? {},
          // The multi-language fallback the card uses when the lesson had no
          // takeaway item, so the back face is never empty.
          description: keypoint.description ?? {},
          image: keypoint.image ?? '',
          // Both: `recap` is what a current app reads (and follows the app's
          // language); `recapText` is all a card saved before 2026-09-10 has,
          // and all an app build older than that knows how to read.
          recap: item.recap ?? {},
          recapText: item.recapText ?? '',
          courseTitle: course?.title ?? {},
          createdAt: item.createdAt,
        };
      })
      .filter(Boolean);

    return { ...page, items };
  }
}
