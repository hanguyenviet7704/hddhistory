import { CoachContentService } from './coach-content.service';

/**
 * The two things this service does that a repository cannot check for itself:
 * it merges four sources into one answer, and it hands a situation answer back
 * the question it was answering.
 *
 * Both are the kind of mistake that reads as data rather than as a crash — a
 * user's rows counted under the wrong kind, or an answer shown under the wrong
 * prompt — which is exactly why they are pinned here.
 */
describe('CoachContentService', () => {
  const day = (iso: string) => new Date(`2026-08-${iso}`);

  function build(options: {
    evidence?: any[];
    statements?: any[];
    answers?: any[];
    dips?: any[];
    situations?: any[];
    users?: any[];
    sessions?: any[];
    /** The single row `findById` answers with, for the delete path. */
    statement?: any;
  }) {
    const evidenceRepository = {
      findForAdmin: jest.fn().mockResolvedValue(options.evidence ?? []),
      aggregateUsersForAdmin: jest.fn().mockResolvedValue(options.evidence ?? []),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const problemStatementRepository = {
      findForAdmin: jest.fn().mockResolvedValue(options.statements ?? []),
      aggregateUsersForAdmin: jest
        .fn()
        .mockResolvedValue(options.statements ?? []),
      findById: jest.fn().mockResolvedValue(options.statement ?? null),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const situationAnswerRepository = {
      findForAdmin: jest.fn().mockResolvedValue(options.answers ?? []),
      aggregateUsersForAdmin: jest.fn().mockResolvedValue(options.answers ?? []),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const dipRepository = {
      findDipsForAdmin: jest.fn().mockResolvedValue(options.dips ?? []),
      aggregateUsersForAdmin: jest.fn().mockResolvedValue(options.dips ?? []),
      findSessionsForAdmin: jest.fn().mockResolvedValue(options.sessions ?? []),
      clearDip: jest.fn().mockResolvedValue({ modifiedCount: 1 }),
    };
    const situationRepository = {
      findPromptsByIds: jest.fn().mockResolvedValue(options.situations ?? []),
    };
    const userRepository = {
      findAdminIdentitiesByIds: jest.fn().mockResolvedValue(options.users ?? []),
    };

    const service = new CoachContentService(
      evidenceRepository as any,
      problemStatementRepository as any,
      situationAnswerRepository as any,
      dipRepository as any,
      situationRepository as any,
      userRepository as any,
    );

    return {
      service,
      situationRepository,
      userRepository,
      evidenceRepository,
      problemStatementRepository,
      situationAnswerRepository,
      dipRepository,
    };
  }

  describe('findUsersForAdmin', () => {
    it('merges the four sources into one row per reader', async () => {
      const { service } = build({
        evidence: [
          { userId: 'u1', count: 2, firstAt: day('02'), lastAt: day('05') },
        ],
        answers: [
          { userId: 'u1', count: 3, firstAt: day('06'), lastAt: day('09') },
          { userId: 'u2', count: 1, firstAt: day('07'), lastAt: day('07') },
        ],
        statements: [
          {
            userId: 'u1',
            kind: 'barrier',
            count: 1,
            firstAt: day('01'),
            lastAt: day('03'),
          },
        ],
        users: [{ _id: 'u1', name: 'Hà', email: 'ha@example.com' }],
      });

      const { rows, total } = await service.findUsersForAdmin({} as any);

      expect(total).toBe(2);
      // Most recently active first — the only order this list is useful in.
      expect(rows.map((row) => row.userId)).toEqual(['u1', 'u2']);

      const [first] = rows;
      expect(first.total).toBe(6);
      expect(first.byKind.evidence).toBe(2);
      expect(first.byKind.situation_answer).toBe(3);
      expect(first.byKind.barrier).toBe(1);
      // Untouched kinds are still columns, not gaps.
      expect(first.byKind.dip).toBe(0);
      // The window spans every source, not just the one that opened it.
      expect(first.firstAt).toEqual(day('01'));
      expect(first.lastAt).toEqual(day('09'));
      expect(first.name).toBe('Hà');
      expect(first.email).toBe('ha@example.com');
    });

    it('leaves identity null when the account is gone', async () => {
      const { service } = build({
        evidence: [
          { userId: 'ghost', count: 1, firstAt: day('02'), lastAt: day('02') },
        ],
        users: [],
      });

      const { rows } = await service.findUsersForAdmin({} as any);

      expect(rows[0].name).toBeNull();
      expect(rows[0].email).toBeNull();
      expect(rows[0].total).toBe(1);
    });

    it('drops statement rows whose kind was filtered out', async () => {
      // All three live in one collection, so the query cannot filter them and
      // a miss here would count a barrier as a quick note.
      const { service } = build({
        statements: [
          {
            userId: 'u1',
            kind: 'barrier',
            count: 4,
            firstAt: day('01'),
            lastAt: day('02'),
          },
          {
            userId: 'u1',
            kind: 'quick_note',
            count: 7,
            firstAt: day('01'),
            lastAt: day('02'),
          },
        ],
      });

      const { rows } = await service.findUsersForAdmin({
        kinds: ['barrier'],
      } as any);

      expect(rows[0].total).toBe(4);
      expect(rows[0].byKind.barrier).toBe(4);
      expect(rows[0].byKind.quick_note).toBe(0);
    });
  });


  describe('findThreadForAdmin', () => {
    const at = (hhmm: string) => new Date(`2026-09-01T${hhmm}:00.000Z`);

    it('reads a live session back as the conversation it was', async () => {
      const { service } = build({
        sessions: [
          {
            _id: 'sess-1',
            entry: 'home',
            habitId: 'hab-1',
            createdAt: at('09:00'),
            turns: [
              { role: 'coach', text: 'Hôm nay có gì mới không?', at: at('09:01') },
              { role: 'user', text: 'tôi mệt quá', at: at('09:02') },
              { role: 'coach', text: 'Mình gom lại thành nháp', at: at('09:03') },
              { role: 'user', text: 'vấn đề thật của tôi là ôm việc', at: at('09:04') },
            ],
          },
        ],
        statements: [
          {
            _id: 'st-1',
            userId: 'u1',
            sessionId: 'sess-1',
            kind: 'problem_statement',
            content: 'vấn đề thật của tôi là ôm việc',
            createdAt: at('09:04'),
          },
        ],
      });

      const { sessions } = await service.findThreadForAdmin({
        userId: 'u1',
      } as any);

      expect(sessions).toHaveLength(1);
      expect(sessions[0].source).toBe('transcript');
      // Four turns in, four messages out — the filed sentence is ONE bubble
      // carrying its label, not a second copy of itself.
      expect(sessions[0].messages).toHaveLength(4);
      expect(sessions[0].messages.map((message) => message.role)).toEqual([
        'coach',
        'user',
        'coach',
        'user',
      ]);
      expect(sessions[0].messages[3].kind).toBe('problem_statement');
      expect(sessions[0].messages[1].kind).toBeUndefined();
    });

    it('appends a row the transcript never held, at its own time', async () => {
      const { service } = build({
        sessions: [
          {
            _id: 'sess-1',
            createdAt: at('09:00'),
            turns: [
              { role: 'user', text: 'chuyện dài lắm', at: at('09:02') },
            ],
          },
        ],
        dips: [
          {
            _id: 'sess-1',
            userId: 'u1',
            dip: 'sáng mai lúc họp',
            createdAt: at('09:05'),
          },
        ],
      });

      const { sessions } = await service.findThreadForAdmin({
        userId: 'u1',
      } as any);

      const texts = sessions[0].messages.map((message) => message.text);
      expect(texts).toEqual(['chuyện dài lắm', 'sáng mai lúc họp']);
      expect(sessions[0].messages[1].kind).toBe('dip');
    });

    it('rebuilds a session whose document has expired', async () => {
      const { service } = build({
        sessions: [],
        answers: [
          {
            _id: 'a1',
            userId: 'u1',
            sessionId: 'gone',
            content: 'mình sẽ nói thẳng',
            situationId: 'sit-1',
            round: 1,
            promptSnapshot: 'Sếp giao thêm việc lúc 6h',
            createdAt: at('08:00'),
          },
        ],
      });

      const { sessions } = await service.findThreadForAdmin({
        userId: 'u1',
      } as any);

      expect(sessions[0].source).toBe('derived');
      expect(sessions[0].messages).toEqual([
        expect.objectContaining({
          role: 'coach',
          text: 'Sếp giao thêm việc lúc 6h',
          derived: true,
        }),
        expect.objectContaining({ role: 'user', text: 'mình sẽ nói thẳng' }),
      ]);
    });

    it('leaves a rebuilt Coach line empty when only the client knows the words', async () => {
      // Ghi nhanh follows a fixed question the API never stores — the screen
      // fills it in from `kind` and says it is reconstructed.
      const { service } = build({
        sessions: [],
        statements: [
          {
            _id: 'st-9',
            userId: 'u1',
            sessionId: 'gone',
            kind: 'quick_note',
            content: 'sau nghỉ lễ thấy oải',
            createdAt: at('08:00'),
          },
        ],
      });

      const { sessions } = await service.findThreadForAdmin({
        userId: 'u1',
      } as any);

      expect(sessions[0].messages[0]).toEqual(
        expect.objectContaining({
          role: 'coach',
          text: null,
          kind: 'quick_note',
          derived: true,
        }),
      );
    });

    it('keeps câu kể out of any session, grouped by its own day', async () => {
      const { service } = build({
        sessions: [
          { _id: 'sess-1', createdAt: at('09:00'), turns: [
            { role: 'user', text: 'trong phiên', at: at('09:01') },
          ] },
        ],
        evidence: [
          {
            _id: 'ev-1',
            userId: 'u1',
            content: 'hôm qua tôi đã nói thẳng',
            createdAt: at('20:00'),
          },
        ],
      });

      const { sessions } = await service.findThreadForAdmin({
        userId: 'u1',
      } as any);

      expect(sessions).toHaveLength(2);
      // Oldest first: a conversation is read forwards.
      expect(sessions[0].sessionId).toBe('sess-1');
      expect(sessions[1].sessionId).toBeNull();
      expect(sessions[1].source).toBe('derived');
    });
  });

  describe('findForAdmin', () => {
    const answerRow = (id: string, round: number) => ({
      _id: id,
      userId: 'u1',
      content: `trả lời ${round}`,
      situationId: 'sit-1',
      round,
      createdAt: day('05'),
    });

    it('hangs the authored question on the answer it belongs to', async () => {
      const { service } = build({
        answers: [answerRow('a1', 1)],
        situations: [
          { _id: 'sit-1', prompt: 'Sếp giao thêm việc lúc 6h', level: 2 },
        ],
      });

      const { rows } = await service.findForAdmin({} as any);

      expect(rows[0].meta.situationPrompt).toBe('Sếp giao thêm việc lúc 6h');
      expect(rows[0].meta.situationLevel).toBe(2);
    });

    it('uses the second stage for a second-round answer', async () => {
      // Round 2 answers a different question; showing the opening prompt would
      // misrepresent what the reader replied to.
      const { service } = build({
        answers: [answerRow('a2', 2)],
        situations: [
          {
            _id: 'sit-1',
            prompt: 'Sếp giao thêm việc lúc 6h',
            promptStage2: 'Sếp nói tiếp: mai phải xong',
          },
        ],
      });

      const { rows } = await service.findForAdmin({} as any);

      expect(rows[0].meta.situationPrompt).toBe('Sếp nói tiếp: mai phải xong');
    });

    it('keeps the answer when its scene is gone from the catalogue', async () => {
      const { service } = build({
        answers: [answerRow('a3', 1)],
        situations: [],
      });

      const { rows } = await service.findForAdmin({} as any);

      expect(rows[0].content).toBe('trả lời 1');
      expect(rows[0].meta.situationPrompt).toBeUndefined();
    });

    it('asks for the scenes once, only for the rows still on the page', async () => {
      const { service, situationRepository } = build({
        answers: [answerRow('a1', 1), answerRow('a2', 1)],
        situations: [{ _id: 'sit-1', prompt: 'Một cảnh' }],
      });

      await service.findForAdmin({} as any);

      expect(situationRepository.findPromptsByIds).toHaveBeenCalledTimes(1);
      expect(situationRepository.findPromptsByIds).toHaveBeenCalledWith([
        'sit-1',
      ]);
    });
  });

  /**
   * Xoá là thao tác duy nhất trên màn này không hoàn tác được, và sáu loại chỉ
   * có bốn nguồn — nên cái phải ghim ở đây là chuyện định tuyến: đúng loại về
   * đúng collection, và `dip` không được kéo theo cả phiên.
   */
  describe('removeForAdmin', () => {
    it('deletes an evidence row straight by id', async () => {
      const { service, evidenceRepository } = build({});

      await service.removeForAdmin('evidence' as any, 'e1');

      expect(evidenceRepository.deleteOne).toHaveBeenCalledWith({ _id: 'e1' });
    });

    it('deletes a situation answer straight by id', async () => {
      const { service, situationAnswerRepository } = build({});

      await service.removeForAdmin('situation_answer' as any, 'a1');

      expect(situationAnswerRepository.deleteOne).toHaveBeenCalledWith({
        _id: 'a1',
      });
    });

    it('refuses a statement row asked for under the wrong kind', async () => {
      // Ba loại nằm chung một collection: id đúng mà loại sai thì đây là cú
      // bấm nhầm dòng, không phải một lệnh xoá hợp lệ.
      const { service, problemStatementRepository } = build({
        statement: { _id: 's1', kind: 'barrier' },
      });

      await expect(
        service.removeForAdmin('quick_note' as any, 's1'),
      ).rejects.toThrow();
      expect(problemStatementRepository.deleteOne).not.toHaveBeenCalled();
    });

    it('deletes a statement row asked for under its own kind', async () => {
      const { service, problemStatementRepository } = build({
        statement: { _id: 's1', kind: 'barrier' },
      });

      await service.removeForAdmin('barrier' as any, 's1');

      expect(problemStatementRepository.deleteOne).toHaveBeenCalledWith({
        _id: 's1',
      });
    });

    it('treats a row written before `kind` existed as vấn đề thật', async () => {
      // Cùng một quy ước với feed, nếu không thì mọi dòng cũ đều 404 khi xoá.
      const { service, problemStatementRepository } = build({
        statement: { _id: 's-old' },
      });

      await service.removeForAdmin('problem_statement' as any, 's-old');

      expect(problemStatementRepository.deleteOne).toHaveBeenCalledWith({
        _id: 's-old',
      });
    });

    it('clears only the dip field, never the session', async () => {
      const { service, dipRepository } = build({});

      await service.removeForAdmin('dip' as any, 'sess-1:dip');

      // Id của feed mang hậu tố; cái đi xuống repository là id phiên trần.
      expect(dipRepository.clearDip).toHaveBeenCalledWith('sess-1');
      expect((dipRepository as any).deleteOne).toBeUndefined();
    });

    it('reports a miss instead of answering success', async () => {
      const { service, evidenceRepository } = build({});
      evidenceRepository.deleteOne.mockResolvedValue({ deletedCount: 0 });

      await expect(
        service.removeForAdmin('evidence' as any, 'gone'),
      ).rejects.toThrow();
    });

    it('reports a miss when the session has no dip to clear', async () => {
      const { service, dipRepository } = build({});
      dipRepository.clearDip.mockResolvedValue({ modifiedCount: 0 });

      await expect(
        service.removeForAdmin('dip' as any, 'sess-1:dip'),
      ).rejects.toThrow();
    });
  });
});
