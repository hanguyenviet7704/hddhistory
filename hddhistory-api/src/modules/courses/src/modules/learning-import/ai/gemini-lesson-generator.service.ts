import { Injectable, Logger } from '@nestjs/common';

import { Configuration } from '@base/config/configuration';

import {
  buildContinuationPrompt,
  buildStreamedLessonPrompt,
  CONTINUATION_RESPONSE_SCHEMA,
  STREAMED_LESSON_RESPONSE_SCHEMA,
} from './lesson-generation.prompt';
import {
  GenerationUsage,
  LessonContinuationInput,
  LessonContinuationResult,
  LessonGenerationError,
  LessonGenerationInput,
  LessonGenerator,
  LessonStreamHandlers,
  LessonStreamResult,
  ResolvedSource,
} from './lesson-generation.types';
import { LessonStreamAssembler } from './lesson-stream-assembler';
import { ILessonKeypoint } from '../interface/learning-import.interface';

const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * Ceiling on one generation pass.
 *
 * A 3000-word lesson is roughly 5-8k tokens depending on the language (CJK and
 * Vietnamese tokenize worse than English), so this leaves real headroom even for
 * the continuation pass, which writes most of the lesson in one go. Running out
 * mid-lesson would hand us truncated JSON, which surfaces as a parse failure
 * rather than as anything actionable -- cheaper to over-allocate. Every current
 * flash model accepts 65536 here, so this is well inside the limit.
 */
const MAX_OUTPUT_TOKENS = 32_768;

// Non-streaming, so this is the whole budget for a multi-minute generation.
// Node's fetch has no timeout of its own; without this an upstream stall would
// hold the job in `generating` until the heartbeat marked it interrupted.
const DEFAULT_TIMEOUT_MS = 10 * 60 * 1000;

/**
 * Gemini implementation of the lesson generator.
 *
 * Raw `fetch` rather than an SDK, matching `OutputPracticeAiService`: it is one
 * POST, the SDK would be the only AI dependency in the tree, and the request
 * shape is stable enough that owning it costs less than tracking a client
 * library. Nothing outside this file knows the provider's name -- see
 * `LessonGenerator`.
 */
@Injectable()
export class GeminiLessonGeneratorService extends LessonGenerator {
  private readonly logger = new Logger(GeminiLessonGeneratorService.name);

  constructor(private readonly configuration: Configuration) {
    super();
  }

  private get apiKey(): string | undefined {
    return this.configuration.getGeminiApiKey?.trim() || undefined;
  }

  /**
   * An ALIAS, not a pinned version, and that is the deliberate part.
   *
   * This feature has already been broken twice by model retirement: it shipped
   * defaulting to `gemini-2.0-flash`, which Google had removed outright ("no
   * longer available"), and the obvious replacement `gemini-2.5-flash` answers
   * "no longer available to new users" for a freshly created project. Both are
   * hard 404s -- an outage that stays until a human notices and redeploys.
   *
   * An alias cannot fail that way. What it can do instead is shift behaviour
   * under a prompt that was tuned against the previous model, and that failure
   * is far gentler here: the output is schema-validated and length-validated,
   * so a worse model shows up as CONTENT_TOO_SHORT or thinner lessons rather
   * than as a dead endpoint.
   *
   * `GEMINI_MODEL` still overrides, so pinning is one env var away whenever
   * someone wants determinism more than availability.
   */
  private get model(): string {
    return this.configuration.getGeminiModel?.trim() || 'gemini-flash-latest';
  }

  private get timeoutMs(): number {
    const raw = Number(this.configuration.getGeminiTimeoutMs);

    return Number.isFinite(raw) && raw > 0 ? raw : DEFAULT_TIMEOUT_MS;
  }

  /**
   * True when the feature can actually run.
   *
   * Checked before a job is created so a missing key is a clear rejection at
   * request time rather than ten jobs that all fail two minutes in.
   */
  isConfigured(): boolean {
    return Boolean(this.apiKey);
  }

  /**
   * The whole lesson in one STREAMED call — the outline handler fires the
   * moment the plan closes (tens of seconds after the source is read), each
   * keypoint the moment its object closes.
   *
   * A stream that dies AFTER the outline landed is not an error to the caller:
   * whatever keypoints fully arrived were already handed over, and the
   * returned result says how many — the continuation fallback owns the rest.
   * A stream that dies BEFORE the outline throws, because nothing usable
   * happened.
   */
  async generateLessonStream(
    input: LessonGenerationInput,
    handlers: LessonStreamHandlers,
  ): Promise<LessonStreamResult> {
    const apiKey = this.apiKey;
    if (!apiKey) {
      throw new LessonGenerationError('GEMINI_API_KEY is not configured');
    }

    const body = this.buildRequestBody(
      input.source,
      buildStreamedLessonPrompt(input),
      STREAMED_LESSON_RESPONSE_SCHEMA,
    );

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    const assembler = new LessonStreamAssembler();
    const usage: GenerationUsage = { inputTokens: 0, outputTokens: 0 };
    let outlineSeen = false;
    const delivered: ILessonKeypoint[] = [];

    try {
      let response: Response;
      try {
        response = await fetch(
          `${API_BASE}/${encodeURIComponent(this.model)}:streamGenerateContent?alt=sse`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: JSON.stringify(body),
            signal: controller.signal,
          },
        );
      } catch (error: any) {
        throw this.asGenerationError(error);
      }

      if (!response.ok || !response.body) {
        const detail = await response.text().catch(() => '');
        this.logger.error(
          `Gemini stream responded ${response.status}: ${detail.slice(0, 500)}`,
        );
        throw new LessonGenerationError(
          `Lesson generation failed (${response.status})`,
        );
      }

      // `alt=sse` frames every chunk as `data: <json>\n\n`. Events may split
      // across network reads, so line-buffer before parsing.
      const decoder = new TextDecoder();
      let pending = '';

      const handleEvent = async (line: string) => {
        if (!line.startsWith('data:')) return;
        const payload = line.slice('data:'.length).trim();
        if (!payload || payload === '[DONE]') return;

        let event: GeminiResponse;
        try {
          event = JSON.parse(payload) as GeminiResponse;
        } catch {
          // A malformed frame is the transport's problem, not fatal to the
          // lesson — later frames carry on from the same text position.
          return;
        }

        const blockReason = event?.promptFeedback?.blockReason;
        if (blockReason) {
          throw new LessonGenerationError(
            `Provider blocked the request (${blockReason})`,
          );
        }
        if (event?.usageMetadata) {
          usage.inputTokens = event.usageMetadata.promptTokenCount ?? usage.inputTokens;
          usage.outputTokens =
            event.usageMetadata.candidatesTokenCount ?? usage.outputTokens;
        }

        const text = event?.candidates?.[0]?.content?.parts
          ?.map(part => part.text ?? '')
          .join('');
        if (!text) return;

        const progress = assembler.push(text);
        if (progress.outline) {
          // Flag AFTER the handler resolves: the handler is what creates the
          // lesson and completes the job, and if IT throws, nothing usable
          // happened — that must surface as a hard failure, not as "partial
          // stream, the continuation will finish it".
          await handlers.onOutline(progress.outline);
          outlineSeen = true;
        }
        // Head and section events feed TTS prefetch; their handlers must be
        // fast (they only ENQUEUE synthesis), so awaiting keeps ordering
        // without meaningfully backpressuring the stream.
        for (const head of progress.heads) {
          await handlers.onKeypointHead?.(head);
        }
        for (const event of progress.sections) {
          await handlers.onSection?.(event);
        }
        for (const { keypoint, index } of progress.keypoints) {
          delivered.push(keypoint);
          await handlers.onKeypoint(keypoint, index);
        }
      };

      try {
        for await (const chunk of response.body as unknown as AsyncIterable<Uint8Array>) {
          pending += decoder.decode(chunk, { stream: true });
          let newline = pending.indexOf('\n');
          while (newline >= 0) {
            const line = pending.slice(0, newline).replace(/\r$/, '');
            pending = pending.slice(newline + 1);
            await handleEvent(line);
            newline = pending.indexOf('\n');
          }
        }
        if (pending.length > 0) await handleEvent(pending);
      } catch (error: any) {
        if (error instanceof LessonGenerationError) throw error;
        // The stream broke mid-flight. Everything delivered so far is already
        // in the caller's hands; with an outline down this is a partial
        // success the continuation fallback finishes, not a failure.
        if (!outlineSeen) throw this.asGenerationError(error);
        this.logger.warn(
          `Lesson stream broke after ${delivered.length} keypoint(s): ${error?.message} — continuation will finish it`,
        );
      }

      if (!outlineSeen) {
        throw new LessonGenerationError(
          'Stream ended before an outline arrived',
        );
      }

      return { keypoints: delivered, usage };
    } finally {
      clearTimeout(timeoutId);
    }
  }

  private asGenerationError(error: any): LessonGenerationError {
    if (error?.name === 'AbortError') {
      return new LessonGenerationError(
        `Lesson generation timed out after ${this.timeoutMs}ms`,
        true,
      );
    }

    return new LessonGenerationError(
      error?.message || 'Lesson generation request failed',
    );
  }

  async generateContinuation(
    input: LessonContinuationInput,
  ): Promise<LessonContinuationResult> {
    const { payload, usage } = await this.request(
      input.source,
      buildContinuationPrompt(input),
      CONTINUATION_RESPONSE_SCHEMA,
    );

    const keypoints = (payload as { keypoints?: ILessonKeypoint[] })?.keypoints;
    if (!keypoints || !Array.isArray(keypoints)) {
      throw new LessonGenerationError('Provider returned no keypoints');
    }

    return { keypoints, usage };
  }

  /**
   * One structured-output round trip: source + prompt in, parsed JSON out.
   *
   * Both phases are the same POST with a different prompt and schema, so the
   * transport -- timeout, error taxonomy, envelope parsing -- lives once here and
   * cannot drift between them.
   */
  private async request(
    source: ResolvedSource,
    prompt: string,
    responseSchema: object,
  ): Promise<{ payload: unknown; usage: GenerationUsage }> {
    const apiKey = this.apiKey;
    if (!apiKey) {
      throw new LessonGenerationError('GEMINI_API_KEY is not configured');
    }

    const body = this.buildRequestBody(source, prompt, responseSchema);

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    let response: Response;
    try {
      response = await fetch(
        `${API_BASE}/${encodeURIComponent(this.model)}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            // Header rather than ?key= so the secret never lands in a proxy or
            // access log that records query strings.
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        },
      );
    } catch (error: any) {
      if (error?.name === 'AbortError') {
        throw new LessonGenerationError(
          `Lesson generation timed out after ${this.timeoutMs}ms`,
          true,
        );
      }
      throw new LessonGenerationError(
        error?.message || 'Lesson generation request failed',
      );
    } finally {
      clearTimeout(timeoutId);
    }

    if (!response.ok) {
      const detail = await response.text().catch(() => '');
      // Logged, not surfaced: the provider's error text can quote the prompt and
      // parts of the user's document, neither of which belongs in an API reply.
      this.logger.error(
        `Gemini responded ${response.status}: ${detail.slice(0, 500)}`,
      );
      throw new LessonGenerationError(
        `Lesson generation failed (${response.status})`,
      );
    }

    const envelope = (await response.json()) as GeminiResponse;

    return {
      payload: this.extractPayload(envelope),
      usage: {
        inputTokens: envelope?.usageMetadata?.promptTokenCount ?? 0,
        outputTokens: envelope?.usageMetadata?.candidatesTokenCount ?? 0,
      },
    };
  }

  private buildRequestBody(
    source: ResolvedSource,
    prompt: string,
    responseSchema: object,
  ) {
    const parts: GeminiPart[] = [];

    if (source.kind === 'pdfBytes') {
      // The document goes FIRST. Instructions that follow their material are
      // followed more closely than instructions the material is appended to.
      parts.push({
        inline_data: {
          mime_type: 'application/pdf',
          data: source.bytes.toString('base64'),
        },
      });
      parts.push({ text: prompt });
    } else if (source.kind === 'remoteUri') {
      // The provider fetches this itself -- see `ResolvedSource`. Costs far more
      // input tokens than a transcript would (a 15-minute talk measured ~80k),
      // and takes tens of seconds, but it is the only path that works at all
      // from a server address, and it reads videos that have no captions.
      parts.push({ fileData: { fileUri: source.uri } });
      parts.push({ text: prompt });
    } else {
      parts.push({ text: prompt });
      parts.push({
        text: `\n\n--- SOURCE TRANSCRIPT ---\n${source.text}`,
      });
    }

    return {
      contents: [{ role: 'user', parts }],
      generationConfig: {
        // Structured output: the response is JSON matching the schema, so there
        // is no fence to strip and no preamble to skip.
        responseMimeType: 'application/json',
        responseSchema,
        maxOutputTokens: MAX_OUTPUT_TOKENS,
      },
    };
  }

  /**
   * Pull the JSON payload out of the response envelope.
   *
   * Every failure here is a provider contract violation rather than a user
   * error, so they all collapse to one AI_FAILED -- there is nothing the user
   * could do differently, and telling them "candidate 0 had no text part" would
   * be worse than useless.
   */
  private extractPayload(envelope: GeminiResponse): unknown {
    const blockReason = envelope?.promptFeedback?.blockReason;
    if (blockReason) {
      throw new LessonGenerationError(
        `Provider blocked the request (${blockReason})`,
      );
    }

    const text = envelope?.candidates?.[0]?.content?.parts
      ?.map(part => part.text ?? '')
      .join('')
      .trim();

    if (!text) {
      const finishReason = envelope?.candidates?.[0]?.finishReason ?? 'unknown';
      throw new LessonGenerationError(
        `Provider returned no content (finishReason: ${finishReason})`,
      );
    }

    try {
      return JSON.parse(text);
    } catch {
      // Nearly always a truncated response -- see MAX_OUTPUT_TOKENS.
      throw new LessonGenerationError('Provider returned malformed JSON');
    }
  }
}

// Only the fields we read. Typed loosely on purpose: the provider adds fields
// over time and a strict shape would reject responses that are perfectly usable.
type GeminiPart =
  | { text?: string }
  | { inline_data: InlineData }
  | { fileData: { fileUri: string } };

interface InlineData {
  mime_type: string;
  data: string;
}

interface GeminiResponse {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  promptFeedback?: { blockReason?: string };
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
  };
}
