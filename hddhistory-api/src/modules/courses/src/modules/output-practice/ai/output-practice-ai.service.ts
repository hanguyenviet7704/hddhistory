import {
  BadGatewayException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import WebSocket from 'ws';

import { Configuration } from '@base/config/configuration';

export type OutputPracticeAiReply = {
  type?: string;
  content?: string;
  options?: OutputPracticeAiReplyOption[];
};

export type OutputPracticeAiReplyOption = {
  value: number;
  label: string;
  description?: string;
};

export type OutputPracticeAiStartResponse = {
  thread_id: string;
  reply?: OutputPracticeAiReply;
};

export type OutputPracticeAiStreamEvent =
  | {
      type: 'stream';
      content: string;
    }
  | {
      type: 'end';
    }
  | {
      type: 'metadata_update';
      keypoint_name?: string;
      practice_option?: string;
      section_id?: string;
      is_summary_turn?: boolean;
    }
  | {
      type: 'error';
      content: string;
    }
  | {
      type: string;
      [key: string]: any;
    };

@Injectable()
export class OutputPracticeAiService {
  private static readonly START_TIMEOUT_MS = 12_000;
  private static readonly WS_HANDSHAKE_TIMEOUT_MS = 30_000;

  constructor(private readonly configuration: Configuration) {}

  private get host() {
    return this.configuration.getOutputPracticeAiHost?.trim();
  }

  private get token() {
    return this.configuration.getOutputPracticeAiSecretToken?.trim();
  }

  private resolveHostProtocols(rawHost: string) {
    const host = rawHost
      .replace(/^https?:\/\//i, '')
      .replace(/^wss?:\/\//i, '')
      .replace(/\/+$/, '');

    const httpProtocol = /^http:\/\//i.test(rawHost) ? 'http' : 'https';
    const wsProtocol =
      /^http:\/\//i.test(rawHost) || /^ws:\/\//i.test(rawHost) ? 'ws' : 'wss';

    return { host, httpProtocol, wsProtocol };
  }

  async startConversation(payload: {
    user_id: string;
    section_id: string;
    language: string;
    ai_config: string;
  }): Promise<OutputPracticeAiStartResponse> {
    if (!this.host) {
      throw new InternalServerErrorException(
        'OUTPUT_PRACTICE_AI_HOST is not configured',
      );
    }
    if (!this.token) {
      throw new InternalServerErrorException(
        'OUTPUT_PRACTICE_AI_SECRET_TOKEN is not configured',
      );
    }

    const rawHost = this.host!;
    const { host, httpProtocol } = this.resolveHostProtocols(rawHost);

    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      OutputPracticeAiService.START_TIMEOUT_MS,
    );

    let res: Response;
    try {
      res = await fetch(`${httpProtocol}://${host}/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': this.token!,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });
    } catch (error: any) {
      if (error?.name === 'AbortError') {
        throw new BadGatewayException('AI start request timed out');
      }
      throw new BadGatewayException(
        error?.message || 'AI start request failed',
      );
    } finally {
      clearTimeout(timeoutId);
    }

    if (!res.ok) {
      const errorText = await res.text();
      throw new BadGatewayException(
        errorText || `AI start request failed (${res.status})`,
      );
    }

    const data = (await res.json()) as OutputPracticeAiStartResponse;

    if (!data?.thread_id) {
      throw new BadGatewayException('AI start response missing thread_id');
    }

    return data;
  }

  async streamConversation(
    payload: Record<string, any>,
    onEvent: (event: OutputPracticeAiStreamEvent) => void,
  ) {
    const { user_id, section_id, thread_id, ...input } = payload;

    if (!user_id || !section_id || !thread_id) {
      throw new BadGatewayException(
        'Missing user_id, section_id or thread_id for AI websocket',
      );
    }

    if (!this.host) {
      throw new InternalServerErrorException(
        'OUTPUT_PRACTICE_AI_HOST is not configured',
      );
    }
    if (!this.token) {
      throw new InternalServerErrorException(
        'OUTPUT_PRACTICE_AI_SECRET_TOKEN is not configured',
      );
    }

    const rawHost = this.host!;
    const { host, wsProtocol } = this.resolveHostProtocols(rawHost);

    const userId = encodeURIComponent(user_id.toString());
    const sectionId = encodeURIComponent(section_id.toString());
    const threadId = encodeURIComponent(thread_id.toString());
    const token = encodeURIComponent(this.token!);
    const wsUrl = `${wsProtocol}://${host}/ws/chat/${userId}/${sectionId}/${threadId}?token=${token}`;

    await new Promise<void>((resolve, reject) => {
      let settled = false;
      let terminalReceived = false;
      const socket = new WebSocket(wsUrl);

      // Guard against a hung handshake: if the socket never opens within the
      // timeout, abort instead of leaving the request pending indefinitely.
      let handshakeTimer: NodeJS.Timeout | null = setTimeout(() => {
        finishWithError('AI websocket handshake timed out');
      }, OutputPracticeAiService.WS_HANDSHAKE_TIMEOUT_MS);

      const clearHandshakeTimer = () => {
        if (handshakeTimer) {
          clearTimeout(handshakeTimer);
          handshakeTimer = null;
        }
      };

      const finishWithError = (message: string) => {
        if (settled) return;
        settled = true;
        clearHandshakeTimer();

        try {
          socket.close();
        } catch {
          // ignore
        }

        reject(new BadGatewayException(message));
      };

      const finishSuccess = () => {
        if (settled) return;
        settled = true;
        clearHandshakeTimer();

        if (!terminalReceived) {
          onEvent({ type: 'end' });
        }

        resolve();
      };

      socket.on('open', () => {
        // Handshake completed — stop the connect timeout.
        clearHandshakeTimer();
        try {
          socket.send(JSON.stringify(input));
        } catch {
          finishWithError('Failed to send message to AI websocket');
        }
      });

      socket.on('message', (data: unknown) => {
        const raw = this.messageEventToString(data);
        if (!raw) return;

        const lines = raw
          .split(/\r?\n/)
          .map(item => item.trim())
          .filter(Boolean);

        for (const line of lines) {
          const parsed = this.parseStreamLine(line);
          if (!parsed) continue;

          onEvent(parsed);

          if (parsed.type === 'end' || parsed.type === 'error') {
            terminalReceived = true;
            try {
              socket.close();
            } catch {
              // ignore
            }
            return;
          }
        }
      });

      socket.on('error', () => {
        finishWithError('AI websocket connection error');
      });

      socket.on('close', () => {
        finishSuccess();
      });
    });
  }

  private messageEventToString(data: unknown): string {
    if (typeof data === 'string') {
      return data;
    }

    if (Buffer.isBuffer(data)) {
      return data.toString('utf8');
    }

    if (Array.isArray(data)) {
      return Buffer.concat(
        data.map(part =>
          Buffer.isBuffer(part) ? part : Buffer.from(part as ArrayBuffer),
        ),
      ).toString('utf8');
    }

    if (data instanceof ArrayBuffer) {
      return Buffer.from(data).toString('utf8');
    }

    if (ArrayBuffer.isView(data)) {
      const view = data as ArrayBufferView;
      return Buffer.from(
        view.buffer,
        view.byteOffset,
        view.byteLength,
      ).toString('utf8');
    }

    return '';
  }

  private parseStreamLine(rawLine: string): OutputPracticeAiStreamEvent | null {
    let line = rawLine.trim();
    if (!line) return null;

    if (line.startsWith('data:')) {
      line = line.slice(5).trim();
    }

    if (!line) return null;

    if (line === '[DONE]') {
      return { type: 'end' };
    }

    try {
      const parsed = JSON.parse(line) as OutputPracticeAiStreamEvent;
      if (!parsed?.type) return null;
      return parsed;
    } catch {
      return null;
    }
  }
}
