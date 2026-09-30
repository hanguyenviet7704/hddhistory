import { Types } from 'mongoose';

import { CourseStatus } from 'src/modules/courses/src/modules/course/enum/course.enum';
import { IOnboardingCourseCandidate } from 'src/modules/courses/src/modules/course/repository/course.repository';

import { rankCourses } from './onboarding-recommendation.ranker';

const course = (
  title: string,
  labels: string[],
  desires: string[],
  lessons = 5,
): IOnboardingCourseCandidate => ({
  _id: new Types.ObjectId(),
  title: { vi: title },
  image: '',
  skillsetId: 's',
  numberOfLesson: lessons,
  status: CourseStatus.PUBLISHED,
  createdAt: new Date('2026-01-01'),
  onboardingLabelCodes: labels,
  onboardingDesireCodes: desires,
});
const labelsByPackage = new Map([
  ['LV-1', ['TT01', 'TT02', 'TT03']],
  ['CX-2', ['CX06', 'CX07']],
]);

describe('rankCourses', () => {
  it('puts a course matching BOTH desire and a problem label first', () => {
    const both = course('both', ['TT01'], ['LV-1']);
    const problemOnly = course('problem', ['TT01', 'TT02'], []);
    const desireOnly = course('desire', [], ['LV-1']);
    const ranked = rankCourses([desireOnly, problemOnly, both], {
      packageCodes: ['LV-1'],
      desireCode: 'LV-1',
      labelsByPackage,
    });
    expect(ranked.map(r => r.course.title.vi)).toEqual([
      'both',
      'desire',
      'problem',
    ]);
    expect(ranked[0].matchReason).toEqual({
      desire: true,
      labelCodes: ['TT01'],
      packageCodes: ['LV-1'],
    });
  });

  it('prefers touching more selected packages, then more labels, then the earlier-picked package', () => {
    const twoPkgs = course('two', ['TT01', 'CX06'], []);
    const oneManyLabels = course('many', ['TT01', 'TT02', 'TT03'], []);
    const secondPkg = course('second', ['CX06'], []);
    const firstPkg = course('first', ['TT02'], []);
    const ranked = rankCourses([secondPkg, oneManyLabels, firstPkg, twoPkgs], {
      packageCodes: ['LV-1', 'CX-2'],
      desireCode: null,
      labelsByPackage,
    });
    expect(ranked.map(r => r.course.title.vi)).toEqual([
      'two',
      'many',
      'first',
      'second',
    ]);
  });

  it('drops courses matching nothing and ranks lesson-less courses last', () => {
    const empty = course('empty', ['TT01'], [], 0);
    const full = course('full', ['TT01'], [], 3);
    const none = course('none', ['QH01'], ['QH-1']);
    const ranked = rankCourses([empty, none, full], {
      packageCodes: ['LV-1'],
      desireCode: null,
      labelsByPackage,
    });
    expect(ranked.map(r => r.course.title.vi)).toEqual(['full', 'empty']);
  });
});
