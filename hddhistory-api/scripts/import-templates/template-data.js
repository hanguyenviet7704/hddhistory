const sharedRules = [
  'id trong row de trong: tao moi.',
  'id co gia tri va tim thay record trong DB: cap nhat theo kieu PATCH.',
  'id co gia tri nhung khong tim thay record: bo qua row, ghi warning, khong dung ca file import.',
  'Cot nao khong co trong file thi backend phai giu nguyen du lieu cu.',
  'Cot object/array co the dung JSON neu template yeu cau. O rong nghia la khong cap nhat field do.',
  'Da ngon ngu dung cot *_vi, *_en. Neu chi co *_vi thi chi update ban dich tieng Viet.',
];

const exerciseQuestionColumns = [
  ['id', 'optional', 'ObjectId learning_item. Co thi update, rong thi create.'],
  ['keypoint_id', 'required', 'ObjectId keypoint cha cua learning_item.'],
  [
    'index',
    'optional',
    'Thu tu learning_item trong keypoint. Co the dung de xen ke theory/exercise trong cung workbook.',
  ],
  ['title_vi', 'required', 'Title learning_item tieng Viet.'],
  ['title_en', 'required', 'Title learning_item tieng Anh.'],
  ['description_vi', 'optional', 'Mo ta learning_item tieng Viet.'],
  ['description_en', 'optional', 'Mo ta learning_item tieng Anh.'],
  ['image', 'optional', 'URL anh learning_item.'],
  [
    'question_code',
    'required',
    'Ma on dinh do BTV nhap. Dung de upsert question va giu exerciseId backend da gen.',
  ],
  [
    'question_type',
    'required',
    'single_choice | multiple_choice | single_choice_no_correct_answer | drag_drop | record.',
  ],
  [
    'level',
    'required',
    'Danh sach level cach nhau bang dau |. Vi du optional_practice|more_practice.',
  ],
  ['max_score', 'optional', 'Field maxScore cua question.'],
  ['explanation_vi', 'optional', 'Question explanation.vi.'],
  ['explanation_en', 'optional', 'Question explanation.en.'],
  [
    'drag_form',
    'optional',
    'Text Gap Filling | Cues Placement | Stress Placement | Arrange the Sequence.',
  ],
  [
    'target_area_vi',
    'optional',
    'Chi dung cho drag_drop. Map vao targetArea.vi.',
  ],
  [
    'target_area_en',
    'optional',
    'Chi dung cho drag_drop. Map vao targetArea.en.',
  ],
  ['record_url', 'optional', 'Field record cua exercise record.'],
  ['record_max_duration', 'optional', 'Field maxDuration cua exercise record.'],
  [
    'record_max_character',
    'optional',
    'Field maxCharacter cua exercise record.',
  ],
];

const exerciseOptionColumns = [
  ['question_code', 'required', 'Noi ve exercises.question_code.'],
  ['value_vi', 'optional', 'Option value tieng Viet.'],
  ['value_en', 'optional', 'Option value tieng Anh.'],
  [
    'is_correct',
    'optional',
    'true/false cho single_choice va multiple_choice.',
  ],
  ['answer_vi', 'optional', 'Drag drop correctAnswer.vi.'],
  ['answer_en', 'optional', 'Drag drop correctAnswer.en.'],
  [
    'document_group_id',
    'optional',
    'Dung cho single_choice_no_correct_answer option, map vao options[].documentGroupId.',
  ],
];

const exerciseDocumentColumns = [
  ['question_code', 'required', 'Noi ve exercises.question_code.'],
  [
    'document_type',
    'required',
    'title | caption | text | video | image | audio | animation.',
  ],
  ['document_content_vi', 'optional', 'data.content.vi.'],
  ['document_content_en', 'optional', 'data.content.en.'],
  ['document_url_vi', 'optional', 'data.url.vi.'],
  ['document_url_en', 'optional', 'data.url.en.'],
  ['document_thumbnail', 'optional', 'data.thumbnail.'],
];

const exerciseDocumentGroupColumns = [
  [
    'question_code',
    'required',
    'Noi ve exercises.question_code cua question single_choice_no_correct_answer.',
  ],
  [
    'document_group_id',
    'required',
    'Map vao documentGroups[].id. Option tro den group nay nam trong sheet exercise_options.document_group_id.',
  ],
  [
    'document_type',
    'required',
    'title | caption | text | video | image | audio | animation.',
  ],
  [
    'document_content_vi',
    'optional',
    'data.content.vi cua document trong documentGroups[].documents.',
  ],
  [
    'document_content_en',
    'optional',
    'data.content.en cua document trong documentGroups[].documents.',
  ],
  [
    'document_url_vi',
    'optional',
    'data.url.vi cua document trong documentGroups[].documents.',
  ],
  [
    'document_url_en',
    'optional',
    'data.url.en cua document trong documentGroups[].documents.',
  ],
  [
    'document_thumbnail',
    'optional',
    'data.thumbnail cua document trong documentGroups[].documents.',
  ],
];

const exerciseGuideColumns = [
  ['column', 'required', 'Ten cot trong cac sheet import.'],
  ['description', 'required', 'Enum, rule, hoac mo ta cach nhap.'],
  ['example', 'optional', 'Vi du hop le.'],
];

const theoryColumns = [
  ['id', 'optional', 'ObjectId learning_item. Co thi update, rong thi create.'],
  [
    'theory_code',
    'required',
    'Moi row la mot theory block. Row dau nhap id/keypoint/title, cac row tiep theo chi can theory_code de them block vao cung learning_item.',
  ],
  ['keypoint_id', 'required', 'ObjectId keypoint cha cua learning_item.'],
  [
    'index',
    'optional',
    'Thu tu learning_item trong keypoint. Co the dung de xen ke theory/exercise trong cung workbook.',
  ],
  ['title_vi', 'required', 'Title learning_item tieng Viet.'],
  ['title_en', 'required', 'Title learning_item tieng Anh.'],
  ['description_vi', 'optional', 'Mo ta learning_item tieng Viet.'],
  ['description_en', 'optional', 'Mo ta learning_item tieng Anh.'],
  ['image', 'optional', 'URL anh learning_item.'],
];

const theoryDocumentColumns = [
  [
    'theory_code',
    'required',
    'Noi chinh xac ve mot row theories.theory_code. Khong nhap nhieu code cach nhau bang dau phay.',
  ],
  [
    'document_type',
    'required',
    'title | caption | text | video | image | audio | animation | explanation.',
  ],
  [
    'explanation_code',
    'optional',
    'Bat buoc khi document_type = explanation. Dung de noi sang sheet explanation_options.',
  ],
  [
    'document_content_vi',
    'optional',
    'data.content.vi. Bat buoc neu type = explanation.',
  ],
  [
    'document_content_en',
    'optional',
    'data.content.en. Bat buoc neu type = explanation.',
  ],
  ['document_url_vi', 'optional', 'data.url.vi.'],
  ['document_url_en', 'optional', 'data.url.en.'],
  ['document_thumbnail', 'optional', 'data.thumbnail.'],
];

const theoryExplanationOptionColumns = [
  ['explanation_code', 'required', 'Noi ve documents.explanation_code.'],
  ['icon', 'optional', 'Map vao data.options[].icon. Co the de trong/null.'],
  ['value_vi', 'required', 'Map vao data.options[].value.vi.'],
  ['value_en', 'required', 'Map vao data.options[].value.en.'],
  ['explanation_vi', 'required', 'Map vao data.options[].explanation.vi.'],
  ['explanation_en', 'required', 'Map vao data.options[].explanation.en.'],
];

const keypointColumns = [
  ['id', 'optional', 'ObjectId keypoint. Co thi update, rong thi create.'],
  ['title_vi', 'required', 'Title keypoint tieng Viet.'],
  ['title_en', 'required', 'Title keypoint tieng Anh.'],
  ['description_vi', 'optional', 'Mo ta keypoint tieng Viet.'],
  ['description_en', 'optional', 'Mo ta keypoint tieng Anh.'],
  ['audio_url_vi', 'optional', 'audio.url.vi.'],
  ['audio_url_en', 'optional', 'audio.url.en.'],
  [
    'estimate_complete_time_vi',
    'optional',
    'estimateCompleTime.vi dung de hien thi.',
  ],
  [
    'estimate_complete_time_en',
    'optional',
    'estimateCompleTime.en dung de hien thi.',
  ],
  [
    'estimate_complete_time_number',
    'optional',
    'So phut backend dung de tinh toan.',
  ],
  ['image', 'optional', 'URL anh keypoint.'],
];

const templates = [
  {
    fileName: 'course-import-template.xlsx',
    title: 'Course Import Template',
    sheetName: 'courses',
    context:
      'Import tao moi/cap nhat course kem roadmap trong cung file Excel. Sheet roadmap_levels va roadmap_nodes lien ket bang course_key.',
    dataSheets: [
      {
        sheetName: 'courses',
        columns: [
          ['id', 'optional', 'ObjectId. Co thi update, rong thi create.'],
          [
            'course_key',
            'required',
            'Ma noi bo trong file Excel de lien ket voi roadmap_levels/roadmap_nodes.',
          ],
          ['title_vi', 'required', 'Title tieng Viet.'],
          ['title_en', 'optional', 'Title tieng Anh.'],
          ['title_zh', 'optional', 'Title tieng Trung.'],
          ['title_ja', 'optional', 'Title tieng Nhat.'],
          ['title_ko', 'optional', 'Title tieng Han.'],
          ['description_vi', 'optional', 'Mo ta tieng Viet.'],
          ['description_en', 'optional', 'Mo ta tieng Anh.'],
          ['description_zh', 'optional', 'Mo ta tieng Trung.'],
          ['description_ja', 'optional', 'Mo ta tieng Nhat.'],
          ['description_ko', 'optional', 'Mo ta tieng Han.'],
          ['image', 'optional', 'URL anh khoa hoc.'],
          ['categoryId', 'optional', 'ObjectId cua category da co trong CMS.'],
          ['status', 'optional', 'draft hoac published.'],
        ],
        sampleRows: [
          {
            id: '',
            course_key: 'english-basic',
            title_vi: 'Tieng Anh co ban',
            title_en: 'Basic English',
            title_zh: '基础英语',
            title_ja: '基礎英語',
            title_ko: '기초 영어',
            description_vi: 'Khoa hoc tieng Anh danh cho nguoi moi bat dau',
            description_en: 'English course for beginners',
            description_zh: '',
            description_ja: '',
            description_ko: '',
            image: 'english-basic.jpg',
            categoryId: '',
            status: 'draft',
          },
        ],
      },
      {
        sheetName: 'roadmap_levels',
        columns: [
          ['course_key', 'required', 'Noi ve courses.course_key.'],
          ['level_key', 'required', 'Ma level trong file Excel.'],
          ['id', 'optional', 'Thu tu level.'],
          ['level', 'required', 'level 1 hoac level 2.'],
          ['titleBadge_vi', 'required', 'Ten badge tieng Viet.'],
          ['titleBadge_en', 'optional', 'Ten badge tieng Anh.'],
          ['titleBadge_zh', 'optional', 'Ten badge tieng Trung.'],
          ['titleBadge_ja', 'optional', 'Ten badge tieng Nhat.'],
          ['titleBadge_ko', 'optional', 'Ten badge tieng Han.'],
          ['lightBadge', 'optional', 'Badge light mode.'],
          ['darkBadge', 'optional', 'Badge dark mode.'],
        ],
        sampleRows: [
          {
            course_key: 'english-basic',
            level_key: 'level-1',
            id: 1,
            level: 'level 1',
            titleBadge_vi: 'Huy hieu co ban',
            titleBadge_en: 'Basic badge',
            titleBadge_zh: '',
            titleBadge_ja: '',
            titleBadge_ko: '',
            lightBadge: 'badge-light.png',
            darkBadge: 'badge-dark.png',
          },
        ],
      },
      {
        sheetName: 'roadmap_nodes',
        columns: [
          ['course_key', 'required', 'Noi ve courses.course_key.'],
          ['level_key', 'required', 'Noi ve roadmap_levels.level_key.'],
          ['node_id', 'optional', 'UUID node. De trong backend se tu tao.'],
          ['title_vi', 'required', 'Title node tieng Viet.'],
          ['title_en', 'optional', 'Title node tieng Anh.'],
          ['title_zh', 'optional', 'Title node tieng Trung.'],
          ['title_ja', 'optional', 'Title node tieng Nhat.'],
          ['title_ko', 'optional', 'Title node tieng Han.'],
          ['description_vi', 'optional', 'Mo ta node tieng Viet.'],
          ['description_en', 'optional', 'Mo ta node tieng Anh.'],
          ['description_zh', 'optional', 'Mo ta node tieng Trung.'],
          ['description_ja', 'optional', 'Mo ta node tieng Nhat.'],
          ['description_ko', 'optional', 'Mo ta node tieng Han.'],
          ['openingVideoId', 'optional', 'ObjectId lesson video mo dau.'],
          ['roleplayId', 'optional', 'ObjectId roleplay lesson.'],
          [
            'lessonIds',
            'optional',
            'Danh sach lesson type lesson, cach nhau bang | hoac xuong dong.',
          ],
          ['outputId', 'optional', 'ObjectId output lesson.'],
          ['closingVideoId', 'optional', 'ObjectId lesson video ket thuc.'],
        ],
        sampleRows: [
          {
            course_key: 'english-basic',
            level_key: 'level-1',
            node_id: '',
            title_vi: 'Chang 1',
            title_en: 'Stage 1',
            title_zh: '',
            title_ja: '',
            title_ko: '',
            description_vi: 'Bat dau khoa hoc',
            description_en: 'Start the course',
            description_zh: '',
            description_ja: '',
            description_ko: '',
            openingVideoId: '',
            roleplayId: '<roleplayLessonId>',
            lessonIds: '<lessonId1>|<lessonId2>',
            outputId: '<outputLessonId>',
            closingVideoId: '',
          },
        ],
      },
    ],
  },
  {
    fileName: 'keypoint-import-template.xlsx',
    title: 'Keypoint Import Template',
    skipInstructions: true,
    context:
      'Import keypoint truoc khi import learning_item. Thu tu keypoint va roadmap se chinh tren CMS.',
    dataSheets: [
      {
        sheetName: 'keypoints',
        columns: keypointColumns,
        sampleRows: [
          {
            id: '',
            title_vi: 'Chao hoi co ban',
            title_en: 'Basic greetings',
            description_vi: 'Lam quen voi cau chao hoi thong dung.',
            description_en: 'Get familiar with common greetings.',
            audio_url_vi: 'https://cdn.example.com/kp-greeting-vi.mp3',
            audio_url_en: 'https://cdn.example.com/kp-greeting-en.mp3',
            estimate_complete_time_vi: '10 phut',
            estimate_complete_time_en: '10 minutes',
            estimate_complete_time_number: 10,
            image: 'https://cdn.example.com/keypoint-greeting.png',
          },
        ],
      },
      {
        sheetName: 'guide',
        columns: exerciseGuideColumns,
        sampleRows: [
          {
            column: 'id',
            description:
              'ObjectId keypoint. Co id thi update, rong thi create.',
            example: '664444444444444444444444',
          },
          {
            column: 'title_vi/title_en',
            description:
              'Map vao title.vi/title.en. Title la bat buoc khi tao moi.',
            example: 'Chao hoi co ban / Basic greetings',
          },
          {
            column: 'description_vi/description_en',
            description:
              'Map vao description.vi/description.en. Co the de trong neu khong import field nay.',
            example:
              'Lam quen voi cau chao hoi thong dung. / Get familiar with common greetings.',
          },
          {
            column: 'audio_url_vi/audio_url_en',
            description: 'Map vao audio.url.vi/audio.url.en.',
            example: 'https://cdn.example.com/kp-greeting-vi.mp3',
          },
          {
            column: 'estimate_complete_time_vi/en',
            description:
              'Map vao estimateCompleTime.vi/en, chi dung lam text hien thi.',
            example: '10 phut / 10 minutes',
          },
          {
            column: 'estimate_complete_time_number',
            description:
              'Map vao estimateCompleTimeNumber. Don vi phut, backend dung de tinh toan.',
            example: '10',
          },
          {
            column: 'image',
            description: 'Map vao image cua keypoint.',
            example: 'https://cdn.example.com/keypoint-greeting.png',
          },
        ],
      },
    ],
  },
  {
    fileName: 'lesson-import-template.xlsx',
    title: 'Lesson Import Template',
    sheetName: 'lessons',
    context:
      'Template cho lesson type = lesson. Co the gan nhieu keypoint bang cach xuong dong trong cung o keypointId/keypointIndex.',
    columns: [
      ['id', 'optional', 'ObjectId cua lesson.'],
      ['courseId', 'required', 'ObjectId course cha.'],
      ['title_vi', 'required', 'Title tieng Viet.'],
      ['title_en', 'optional', 'Title tieng Anh.'],
      ['title_zh', 'optional', 'Title tieng Trung.'],
      ['title_ja', 'optional', 'Title tieng Nhat.'],
      ['title_ko', 'optional', 'Title tieng Han.'],
      ['description_vi', 'optional', 'Mo ta tieng Viet.'],
      ['description_en', 'optional', 'Mo ta tieng Anh.'],
      ['description_zh', 'optional', 'Mo ta tieng Trung.'],
      ['description_ja', 'optional', 'Mo ta tieng Nhat.'],
      ['description_ko', 'optional', 'Mo ta tieng Han.'],
      ['image', 'optional', 'URL anh lesson.'],
      ['type', 'optional', 'Loai lesson. Gia tri mac dinh thuong la lesson.'],
      ['status', 'optional', 'draft hoac published.'],
      ['estimate_complete_time_vi', 'optional', 'Text thoi luong tieng Viet.'],
      ['estimate_complete_time_en', 'optional', 'Text thoi luong tieng Anh.'],
      ['estimate_complete_time_zh', 'optional', 'Text thoi luong tieng Trung.'],
      ['estimate_complete_time_ja', 'optional', 'Text thoi luong tieng Nhat.'],
      ['estimate_complete_time_ko', 'optional', 'Text thoi luong tieng Han.'],
      [
        'estimate_complete_time_number',
        'optional',
        'So phut backend dung de tinh.',
      ],
      [
        'keypointId',
        'optional',
        'ObjectId keypoint. Nhieu keypoint thi xuong dong trong cung o.',
      ],
      [
        'keypointIndex',
        'optional',
        'Thu tu keypoint. Moi dong tuong ung voi mot dong keypointId.',
      ],
    ],
    sampleRows: [
      {
        id: '',
        courseId: '<courseId>',
        title_vi: 'Bai 1: Chao hoi',
        title_en: 'Lesson 1: Greetings',
        title_zh: '第1课：问候',
        title_ja: '第1課：挨拶',
        title_ko: '1과: 인사',
        description_vi: 'Hoc cach chao hoi va gioi thieu ban than',
        description_en: 'Learn greetings and self-introduction',
        description_zh: '',
        description_ja: '',
        description_ko: '',
        image: 'lesson-greetings.jpg',
        type: 'lesson',
        status: 'draft',
        estimate_complete_time_vi: '10 phut',
        estimate_complete_time_en: '10 minutes',
        estimate_complete_time_zh: '',
        estimate_complete_time_ja: '',
        estimate_complete_time_ko: '',
        estimate_complete_time_number: 10,
        keypointId: '<keypointId1>\n<keypointId2>\n<keypointId3>\n',
        keypointIndex: '1\n2\n3\n',
      },
      {
        id: '',
        courseId: '<courseId>',
        title_vi: 'Bai 2: So dem va thoi gian',
        title_en: 'Lesson 2: Numbers and Time',
        title_zh: '第2课：数字和时间',
        title_ja: '第2課：数字と時間',
        title_ko: '2과: 숫자와 시간',
        description_vi: 'Hoc so dem, ngay thang va cach noi thoi gian',
        description_en: 'Learn numbers, dates and telling time',
        description_zh: '',
        description_ja: '',
        description_ko: '',
        image: 'lesson-numbers.jpg',
        type: 'lesson',
        status: 'draft',
        estimate_complete_time_vi: '15 phut',
        estimate_complete_time_en: '15 minutes',
        estimate_complete_time_zh: '',
        estimate_complete_time_ja: '',
        estimate_complete_time_ko: '',
        estimate_complete_time_number: 15,
        keypointId: '',
        keypointIndex: '',
      },
      {
        id: '',
        courseId: '<courseId>',
        title_vi: 'Bai 3: Mua sam',
        title_en: 'Lesson 3: Shopping',
        title_zh: '第3课：购物',
        title_ja: '第3課：買い物',
        title_ko: '3과: 쇼핑',
        description_vi: 'Tu vung va hoi thoai khi di mua sam',
        description_en: 'Vocabulary and conversation for shopping',
        description_zh: '',
        description_ja: '',
        description_ko: '',
        image: 'lesson-shopping.jpg',
        type: 'lesson',
        status: 'published',
        estimate_complete_time_vi: '20 phut',
        estimate_complete_time_en: '20 minutes',
        estimate_complete_time_zh: '',
        estimate_complete_time_ja: '',
        estimate_complete_time_ko: '',
        estimate_complete_time_number: 20,
        keypointId: '',
        keypointIndex: '',
      },
    ],
  },
  {
    fileName: 'output-lesson-import-template.xlsx',
    title: 'Output Lesson Import Template',
    sheetName: 'output_lessons',
    context:
      'Template cho lesson type = output. AIConfig quan trong neu lesson duoc dung cho output practice.',
    columns: [
      ['id', 'optional', 'ObjectId cua output lesson.'],
      ['course_id', 'required', 'ObjectId course cha.'],
      [
        'title',
        'optional',
        'Object JSON da ngon ngu cho title. Neu de trong, backend hien tai co the default Practice khi create.',
      ],
      ['description', 'optional', 'Object JSON da ngon ngu cho description.'],
      ['image', 'optional', 'URL anh output lesson.'],
      [
        'estimate_complete_time',
        'optional',
        'Object JSON da ngon ngu cho text estimate time.',
      ],
      [
        'estimate_complete_time_number',
        'optional',
        'So phut backend dung de tinh.',
      ],
      ['icon_id', 'optional', 'ObjectId tag dung lam icon.'],
      ['light_icon_id', 'optional', 'ObjectId tag dung lam light icon.'],
      ['animation_id', 'optional', 'ObjectId avatar.'],
      ['ai_config', 'optional', 'Chuoi AIConfig cua output lesson.'],
    ],
    sampleRows: [
      {
        id: '',
        course_id: '663333333333333333333333',
        title: '{"vi":"Thuc hanh hoi thoai","en":"Conversation practice"}',
        description:
          '{"vi":"Bai output de luyen phan xa giao tiep.","en":"Output lesson for spoken interaction practice."}',
        image: 'https://cdn.example.com/output-practice.png',
        estimate_complete_time: '{"vi":"8 phut","en":"8 minutes"}',
        estimate_complete_time_number: 8,
        icon_id: '666666666666666666666666',
        light_icon_id: '667777777777777777777777',
        animation_id: '668888888888888888888888',
        ai_config: 'assistant=v2;temperature=0.3',
      },
    ],
  },
  {
    fileName: 'video-lesson-import-template.xlsx',
    title: 'Video Lesson Import Template',
    sheetName: 'video_lessons',
    context:
      'Template cho lesson type = video. video_json bat buoc neu tao moi video lesson.',
    columns: [
      ['id', 'optional', 'ObjectId cua video lesson.'],
      ['course_id', 'required', 'ObjectId course cha.'],
      [
        'learning_item_id',
        'optional',
        'ObjectId learning_item neu video can lien ket voi timed questions.',
      ],
      ['title', 'required', 'Object JSON da ngon ngu cho title.'],
      ['description', 'optional', 'Object JSON da ngon ngu cho description.'],
      ['image', 'optional', 'URL anh fallback.'],
      ['video', 'required', 'Object JSON theo shape LessonVideoDto.'],
      [
        'estimate_complete_time',
        'optional',
        'Object JSON da ngon ngu cho text estimate time.',
      ],
      [
        'estimate_complete_time_number',
        'optional',
        'So phut backend dung de tinh.',
      ],
      ['icon_id', 'optional', 'ObjectId tag dung lam icon.'],
      ['light_icon_id', 'optional', 'ObjectId tag dung lam light icon.'],
      ['animation_id', 'optional', 'ObjectId avatar.'],
    ],
    sampleRows: [
      {
        id: '',
        course_id: '663333333333333333333333',
        learning_item_id: '',
        title: '{"vi":"Video mau chao hoi","en":"Greeting sample video"}',
        description:
          '{"vi":"Video tong quan cho bai hoc chao hoi.","en":"Overview video for greetings."}',
        image: 'https://cdn.example.com/video-cover.png',
        video:
          '{"url":"https://cdn.example.com/videos/greeting.mp4","thumbnail":"https://cdn.example.com/videos/greeting-thumb.jpg","summary":{"vi":"<p>Tom tat video</p>","en":"<p>Video summary</p>"}}',
        estimate_complete_time: '{"vi":"6 phut","en":"6 minutes"}',
        estimate_complete_time_number: 6,
        icon_id: '666666666666666666666666',
        light_icon_id: '667777777777777777777777',
        animation_id: '668888888888888888888888',
      },
    ],
  },
  {
    fileName: 'learning-item-import-template.xlsx',
    title: 'Learning Item Import Template',
    skipInstructions: true,
    context:
      'Template chung cho learning_item type = theory va exercise. Neu workbook co ca sheets theories va exercises thi backend import ca hai trong cung job.',
    dataSheets: [
      {
        sheetName: 'theories',
        columns: theoryColumns,
        sampleRows: [
          {
            id: '',
            theory_code: 'greeting_theory_001_1',
            keypoint_id: '664444444444444444444444',
            index: 1,
            title_vi: 'Ly thuyet chao hoi',
            title_en: 'Greeting theory',
            description_vi: 'Giai thich mau cau chao hoi co ban.',
            description_en: 'Explain common greeting patterns.',
            image: 'https://cdn.example.com/li-theory-greeting.png',
          },
          {
            id: '',
            theory_code: 'greeting_theory_001_2',
            keypoint_id: '',
            index: '',
            title_vi: '',
            title_en: '',
            description_vi: '',
            description_en: '',
            image: '',
          },
        ],
      },
      {
        sheetName: 'theory_documents',
        columns: theoryDocumentColumns,
        sampleRows: [
          {
            theory_code: 'greeting_theory_001_1',
            document_type: 'title',
            explanation_code: '',
            document_content_vi: 'Chao hoi',
            document_content_en: 'Greetings',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
          {
            theory_code: 'greeting_theory_001_1',
            document_type: 'text',
            explanation_code: '',
            document_content_vi: 'Xin chao la cach chao thong dung.',
            document_content_en: 'Hello is a common greeting.',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
          {
            theory_code: 'greeting_theory_001_2',
            document_type: 'title',
            explanation_code: '',
            document_content_vi: 'Ngu canh chao hoi',
            document_content_en: 'Greeting context',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
          {
            theory_code: 'greeting_theory_001_2',
            document_type: 'explanation',
            explanation_code: 'greeting_exp_001',
            document_content_vi: 'Chon cau dung',
            document_content_en: 'Choose the right sentence',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
        ],
      },
      {
        sheetName: 'theory_explanation_options',
        columns: theoryExplanationOptionColumns,
        sampleRows: [
          {
            explanation_code: 'greeting_exp_001',
            icon: '',
            value_vi: 'Xin chao',
            value_en: 'Hello',
            explanation_vi: 'Dung trong ngu canh thong thuong.',
            explanation_en: 'Used in common situations.',
          },
          {
            explanation_code: 'greeting_exp_001',
            icon: '',
            value_vi: 'Tam biet',
            value_en: 'Goodbye',
            explanation_vi: 'Khong phu hop khi bat dau cuoc gap.',
            explanation_en: 'Not suitable when starting a meeting.',
          },
        ],
      },
      {
        sheetName: 'theory_guide',
        columns: exerciseGuideColumns,
        sampleRows: [
          {
            column: 'learning_item_type',
            description:
              'Khong co trong sheet. Sheet theories import LearningItemType = theory, sheet exercises import LearningItemType = exercise.',
            example: 'theory',
          },
          {
            column: 'theory_code',
            description:
              'Ma on dinh do BTV nhap. Moi row trong theories tao mot theory block rieng trong cung learning_item neu row sau khong lap lai id/keypoint/title.',
            example:
              'row 1: greeting_theory_001_1, row 2: greeting_theory_001_2',
          },
          {
            column: 'id',
            description:
              'ObjectId learning_item. Co id thi update, rong thi create.',
            example: '664444444444444444444444',
          },
          {
            column: 'keypoint_id',
            description: 'ObjectId keypoint cha cua learning_item theory.',
            example: '664444444444444444444444',
          },
          {
            column: 'index',
            description:
              'Thu tu learning_item trong keypoint. Dung de xen ke theory va exercise khi workbook co ca 2 sheet. Neu de trong khi create, backend tu lay index lon nhat + 1.',
            example: '1',
          },
          {
            column: 'title_vi/title_en',
            description: 'Title cua learning_item theory theo ngon ngu.',
            example: 'Ly thuyet chao hoi / Greeting theory',
          },
          {
            column: 'description_vi/description_en',
            description:
              'Mo ta cua learning_item theory theo ngon ngu. Co the de trong neu khong import field nay.',
            example:
              'Giai thich mau cau chao hoi co ban. / Explain common greeting patterns.',
          },
          {
            column: 'theory block',
            description:
              'Khong can nhap theory_block_id. Co the nhap nhieu theory_code cach nhau bang dau phay trong 1 row de gom nhieu document code vao cung learning_item.',
            example: 'greeting_theory_001_1,greeting_theory_001_2',
          },
          {
            column: 'tag_id',
            description:
              'Khong nam trong sheet documents vi IDocument khong co tagId. Neu import tagId thi chi ap dung o cap theory block ITheoryDocument.tagId, khong ap dung cho tung document item.',
            example: '662222222222222222222222',
          },
          {
            column: 'documents.document row order',
            description:
              'Khong can nhap document_id. Sheet theory_documents dung theory_code de chia document vao dung learning_item; importer tu danh document.id theo thu tu row.',
            example:
              '2 row documents co theory_code=greeting_theory_001_1 -> documents[0].document id 1,2',
          },
          {
            column: 'documents.document_type',
            description:
              'Enum DocumentType. Gia tri hop le: title | caption | text | video | image | audio | animation | explanation.',
            example: 'text',
          },
          {
            column: 'documents.document_content_vi/en',
            description:
              'Map vao data.content theo ngon ngu. Bat buoc neu document_type = explanation.',
            example: 'Chao hoi / Greetings',
          },
          {
            column: 'documents.document_url_vi/en',
            description:
              'Map vao data.url theo ngon ngu, dung cho video/image/audio/animation neu can URL rieng tung ngon ngu.',
            example: 'https://cdn.example.com/audio/greeting-vi.mp3',
          },
          {
            column: 'documents.document_thumbnail',
            description: 'Map vao data.thumbnail.',
            example: 'https://cdn.example.com/thumbs/greeting.jpg',
          },
          {
            column: 'documents.explanation_code',
            description:
              'Bat buoc khi document_type = explanation. Sheet theory_explanation_options dung ma nay de noi options vao data.options.',
            example: 'greeting_exp_001',
          },
          {
            column: 'theory_explanation_options',
            description:
              'Moi row la 1 data.options[] cua document explanation. Khong can JSON trong sheet documents; importer danh so data.options[].id theo thu tu row.',
            example: 'greeting_exp_001, value_vi=Xin chao, explanation_vi=Dung',
          },
        ],
      },
      {
        sheetName: 'exercises',
        columns: exerciseQuestionColumns,
        sampleRows: [
          {
            id: '',
            keypoint_id: '665555555555555555555555',
            index: 2,
            title_vi: 'Bai tap chao hoi',
            title_en: 'Greeting exercise',
            description_vi:
              'Luyen tap thong qua cau hoi trac nghiem va keo tha.',
            description_en: 'Practice with multiple choice and drag-drop.',
            image: 'https://cdn.example.com/li-exercise-greeting.png',
            question_code: 'greeting_q_001',
            question_type: 'multiple_choice',
            level: 'optional_practice',
            max_score: 10,
            explanation_vi: 'Xin chao la cau chao phu hop.',
            explanation_en: 'Hello is the appropriate greeting.',
            drag_form: '',
            target_area_vi: '',
            target_area_en: '',
            record_url: '',
            record_max_duration: '',
            record_max_character: '',
          },
          {
            id: '',
            keypoint_id: '',
            index: '',
            title_vi: '',
            title_en: '',
            description_vi: '',
            description_en: '',
            image: '',
            question_code: 'greeting_q_002',
            question_type: 'drag_drop',
            level: 'more_practice',
            max_score: 10,
            explanation_vi: 'Hoan thanh thanh Xin chao.',
            explanation_en: 'Combine to form Hello.',
            drag_form: 'Arrange the Sequence',
            target_area_vi: 'Keo cac tu vao day de tao cau chao.',
            target_area_en: 'Drag the words here to form a greeting.',
            record_url: '',
            record_max_duration: '',
            record_max_character: '',
          },
          {
            id: '',
            keypoint_id: '',
            index: '',
            title_vi: '',
            title_en: '',
            description_vi: '',
            description_en: '',
            image: '',
            question_code: 'greeting_q_003',
            question_type: 'single_choice_no_correct_answer',
            level: 'weak_point',
            max_score: 5,
            explanation_vi: 'Khong co dap an dung tuyet doi.',
            explanation_en: 'There is no single correct answer.',
            drag_form: '',
            target_area_vi: '',
            target_area_en: '',
            record_url: '',
            record_max_duration: '',
            record_max_character: '',
          },
          {
            id: '',
            keypoint_id: '',
            index: '',
            title_vi: '',
            title_en: '',
            description_vi: '',
            description_en: '',
            image: '',
            question_code: 'greeting_q_004',
            question_type: 'record',
            level: 'more_practice|optional_practice',
            max_score: 10,
            explanation_vi: 'Ghi am cau tra loi ngan gon va ro rang.',
            explanation_en: 'Record a short and clear answer.',
            drag_form: '',
            target_area_vi: '',
            target_area_en: '',
            record_url: 'https://cdn.example.com/audio/greeting-prompt.mp3',
            record_max_duration: 60,
            record_max_character: 250,
          },
        ],
      },
      {
        sheetName: 'exercise_options',
        columns: exerciseOptionColumns,
        sampleRows: [
          {
            question_code: 'greeting_q_001',
            value_vi: 'Xin chao',
            value_en: 'Hello',
            is_correct: true,
            answer_vi: '',
            answer_en: '',
            document_group_id: '',
          },
          {
            question_code: 'greeting_q_001',
            value_vi: 'Tam biet',
            value_en: 'Goodbye',
            is_correct: false,
            answer_vi: '',
            answer_en: '',
            document_group_id: '',
          },
          {
            question_code: 'greeting_q_002',
            value_vi: 'Xin',
            value_en: 'Hel',
            is_correct: '',
            answer_vi: 'Xin',
            answer_en: 'Hel',
            document_group_id: '',
          },
          {
            question_code: 'greeting_q_002',
            value_vi: 'chao',
            value_en: 'lo',
            is_correct: '',
            answer_vi: 'chao',
            answer_en: 'lo',
            document_group_id: '',
          },
          {
            question_code: 'greeting_q_003',
            value_vi: 'Xin chao',
            value_en: 'Hello',
            is_correct: '',
            answer_vi: '',
            answer_en: '',
            document_group_id: 'group-a',
          },
          {
            question_code: 'greeting_q_003',
            value_vi: 'Chao ban',
            value_en: 'Hi there',
            is_correct: '',
            answer_vi: '',
            answer_en: '',
            document_group_id: 'group-b',
          },
        ],
      },
      {
        sheetName: 'exercise_documents',
        columns: exerciseDocumentColumns,
        sampleRows: [
          {
            question_code: 'greeting_q_001',
            document_type: 'text',
            document_content_vi: 'Ban nen noi gi khi gap nguoi moi?',
            document_content_en:
              'What should you say when meeting someone new?',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
          {
            question_code: 'greeting_q_002',
            document_type: 'text',
            document_content_vi: 'Sap xep cac manh de tao thanh cau chao.',
            document_content_en: 'Arrange the pieces to form a greeting.',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
          {
            question_code: 'greeting_q_004',
            document_type: 'audio',
            document_content_vi: '',
            document_content_en: '',
            document_url_vi:
              'https://cdn.example.com/audio/greeting-prompt-vi.mp3',
            document_url_en:
              'https://cdn.example.com/audio/greeting-prompt-en.mp3',
            document_thumbnail: '',
          },
        ],
      },
      {
        sheetName: 'exercise_document_groups',
        columns: exerciseDocumentGroupColumns,
        sampleRows: [
          {
            question_code: 'greeting_q_003',
            document_group_id: 'group-a',
            document_type: 'text',
            document_content_vi: 'Trang trong va an toan.',
            document_content_en: 'Polite and safe.',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
          {
            question_code: 'greeting_q_003',
            document_group_id: 'group-b',
            document_type: 'text',
            document_content_vi: 'Than mat hon.',
            document_content_en: 'More casual.',
            document_url_vi: '',
            document_url_en: '',
            document_thumbnail: '',
          },
        ],
      },
      {
        sheetName: 'exercise_guide',
        columns: exerciseGuideColumns,
        sampleRows: [
          {
            column: 'learning_item_type',
            description:
              'Khong co trong sheet. Sheet theories import LearningItemType = theory, sheet exercises import LearningItemType = exercise.',
            example: 'exercise',
          },
          {
            column: 'id',
            description:
              'ObjectId learning_item. Co id thi update, rong thi create. Cac dong tiep theo de trong id se thuoc learning_item gan nhat phia tren.',
            example: '665555555555555555555555',
          },
          {
            column: 'keypoint_id',
            description:
              'ObjectId keypoint cha. Chi can dien o dong dau cua learning item; cac dong document tiep theo co the de trong.',
            example: '665555555555555555555555',
          },
          {
            column: 'index',
            description:
              'Thu tu learning_item trong keypoint. Dung de xen ke theory va exercise khi workbook co ca 2 sheet. Neu de trong khi create, backend tu lay index lon nhat + 1.',
            example: '2',
          },
          {
            column: 'title_vi/title_en',
            description:
              'Title cua learning_item theo ngon ngu. Chi can dien o dong dau cua learning item.',
            example: 'Bai tap chao hoi / Greeting exercise',
          },
          {
            column: 'description_vi/description_en',
            description:
              'Mo ta cua learning_item theo ngon ngu. Co the de trong neu khong import field nay.',
            example: 'Luyen tap chao hoi / Greeting practice',
          },
          {
            column: 'image',
            description:
              'URL anh cua learning_item. Co the de trong neu khong import field nay.',
            example: 'https://cdn.example.com/li-exercise-greeting.png',
          },
          {
            column: 'question_code',
            description:
              'Ma on dinh do BTV nhap. Backend dung de upsert question va giu exerciseId da gen. Khong match question theo thu tu dong.',
            example: 'greeting_q_001',
          },
          {
            column: 'question_type',
            description:
              'Enum ExerciseType. Gia tri hop le: single_choice | multiple_choice | single_choice_no_correct_answer | drag_drop | record.',
            example: 'multiple_choice',
          },
          {
            column: 'level',
            description:
              'Enum KeypointLevel. Nhap nhieu level trong 1 o, cach nhau bang dau |. Gia tri hop le: optional_practice | more_practice | weak_point.',
            example: 'optional_practice|more_practice',
          },
          {
            column: 'max_score',
            description:
              'Diem toi da cua question. Ap dung cho cac loai question.',
            example: '10',
          },
          {
            column: 'explanation_vi/explanation_en',
            description:
              'Giai thich cua question theo ngon ngu. Co the de trong neu khong co explanation.',
            example: 'Xin chao la cau chao phu hop. / Hello is appropriate.',
          },
          {
            column: 'exercise_options',
            description:
              'Dung cho single_choice/multiple_choice. Moi row la 1 option, value_vi/en la text, is_correct la true/false.',
            example: 'greeting_q_001, Xin chao, Hello, true',
          },
          {
            column: 'exercise_options',
            description:
              'Dung cho drag_drop. Moi row la 1 item, value_vi/en la text, answer_vi/en la correctAnswer. Importer tu danh id theo thu tu row.',
            example: 'greeting_q_002, value_vi=Xin, answer_vi=Xin',
          },
          {
            column: 'exercise_options',
            description:
              'Dung cho single_choice_no_correct_answer. Moi row la 1 option, document_group_id map vao documentGroups[].id.',
            example:
              'greeting_q_003, value_vi=Xin chao, document_group_id=group-a',
          },
          {
            column: 'drag_form',
            description:
              'Chi dung khi question_type = drag_drop. Enum FormDragDropType: Text Gap Filling | Cues Placement | Stress Placement | Arrange the Sequence.',
            example: 'Arrange the Sequence',
          },
          {
            column: 'target_area_vi/target_area_en',
            description:
              'Chi dung khi question_type = drag_drop. Map vao targetArea.vi/targetArea.en.',
            example:
              'Keo cac tu vao day de tao cau chao. / Drag the words here to form a greeting.',
          },
          {
            column: 'record_url',
            description:
              'Chi dung khi question_type = record. URL/file record prompt neu co.',
            example: 'https://cdn.example.com/audio/greeting-prompt.mp3',
          },
          {
            column: 'record_max_duration',
            description:
              'Chi dung khi question_type = record. Thoi luong toi da tinh bang giay.',
            example: '60',
          },
          {
            column: 'record_max_character',
            description:
              'Chi dung khi question_type = record. So ky tu toi da neu bai record co text answer.',
            example: '250',
          },
          {
            column: 'exercise_documents.document_type',
            description:
              'Enum DocumentType trong sheet exercise_documents. Tao question.document[]. Tam thoi khong dung explanation trong exercise. Gia tri hop le: title | caption | text | video | image | audio | animation.',
            example: 'text',
          },
          {
            column: 'exercise_documents.document_content_vi/en',
            description: 'data.content theo ngon ngu cua question.document[].',
            example: 'Ban nen noi gi khi gap nguoi moi? / What should you say?',
          },
          {
            column: 'exercise_document_groups.question_code',
            description:
              'Phai khop question_code cua question single_choice_no_correct_answer trong sheet exercises.',
            example: 'greeting_q_003',
          },
          {
            column: 'exercise_document_groups.document_group_id',
            description:
              'Map vao documentGroups[].id. Option lien quan nam trong sheet exercise_options voi cung document_group_id.',
            example: 'group-a',
          },
        ],
      },
    ],
  },
];

module.exports = {
  sharedRules,
  templates,
};
