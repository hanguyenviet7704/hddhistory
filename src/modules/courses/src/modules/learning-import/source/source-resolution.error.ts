import { ImportErrorCode } from '../enum/learning-import.enum';

/**
 * A source we could not turn into material for the model.
 *
 * Carries the `ImportErrorCode` so the runner can record exactly what went wrong
 * without matching on message text -- the code is what the app turns into a
 * sentence the user can act on ("video này không có phụ đề"), and it is also what
 * decides whether the attempt costs a quota slot.
 */
export class SourceResolutionError extends Error {
  constructor(
    readonly code: ImportErrorCode,
    message: string,
  ) {
    super(message);
    this.name = 'SourceResolutionError';
  }
}
