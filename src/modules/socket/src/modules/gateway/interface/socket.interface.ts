export interface IDataSendMessage {
  room?: string;
  event: string;
  payload: any;
}

export interface IDataJoinRoom {
  room: string;
}

export enum SocketClientEvent {
  JOIN_ROOM = 'joinRoom',
  SEND_MESSAGE = 'sendMessage',
  STREAM_MESSAGE = 'streamMessage',
}

export enum SocketServerEvent {
  JOINED_ROOM = 'joinedRoom',
  JOIN_ROOM_ERROR = 'joinRoomError',
  CHAT_STARTED = 'chat:started',
  CHAT_CHUNK = 'chat:chunk',
  CHAT_ENDED = 'chat:ended',
  OUTPUT_PRACTICE_EVENT = 'output-practice:event',
  /**
   * Coach is writing — the text so far, in pieces.
   *
   * A PREVIEW of the turn the client is still waiting on over REST, never the
   * turn itself: no step, no chips, no scene, and never the closing sentence
   * while a gate may still replace it. A client that ignores these events loses
   * the typing effect and nothing else.
   */
  COACH_CHUNK = 'coach:chunk',
  /** Coach has started writing this turn — clears any earlier preview. */
  COACH_STARTED = 'coach:started',
  /** Nothing more is coming for this turn; the REST response is the answer. */
  COACH_ENDED = 'coach:ended',
}

/**
 * The room one reader's coach preview is emitted into.
 *
 * Derived from the verified token at connection time and never from a client
 * payload — see the note in `SocketService.handleConnection`. Keyed on the
 * READER rather than on the session so the client can be listening before the
 * session it is about to open exists.
 */
export function coachRoomFor(userId: string): string {
  return `coach:${userId}`;
}
