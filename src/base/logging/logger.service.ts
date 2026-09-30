// import * as path from 'path';

import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
import * as winston from 'winston';
// import DailyRotateFile from 'winston-daily-rotate-file';

export interface LogPayload {
  message: string;
  context?: string;
  trace?: any;
}

@Injectable()
export class LoggerService implements NestLoggerService {
  private logger: winston.Logger;

  constructor() {
    // const logDir = path.join(process.cwd(), 'logs');

    this.logger = winston.createLogger({
      level: 'warn', // Temporarily suppress info/debug logs.
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
            winston.format.printf(info => {
              const ctx = info.context ? `[${info.context}]` : '';
              return `${info.timestamp} [${info.level}] ${ctx} ${info.message}`;
            }),
          ),
        }),

        // new DailyRotateFile({
        //   dirname: logDir,
        //   filename: 'hddhistory-api-%DATE%.log',
        //   datePattern: 'YYYY-MM-DD',
        //   zippedArchive: false,
        //   maxSize: '10m',
        //   maxFiles: 10,
        //   format: winston.format.combine(
        //     winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        //     winston.format.errors({ stack: true }),
        //     winston.format.json(),
        //   ),
        // }),
      ],
    });
  }

  private formatTrace(trace?: any): string {
    if (!trace) return '';
    if (typeof trace === 'string') return trace;
    if (trace instanceof Error) return trace.stack || trace.message;
    try {
      return JSON.stringify(trace, null, 2);
    } catch {
      return String(trace);
    }
  }

  private buildMessage(
    payload: LogPayload | string,
    context?: string,
  ): {
    msg: string;
    ctx?: string;
    trc?: string;
  } {
    if (typeof payload === 'string') {
      return { msg: payload, ctx: context, trc: '' };
    }
    return {
      msg: payload.message,
      ctx: payload.context,
      trc: this.formatTrace(payload.trace),
    };
  }

  private getStackInfo(stack?: string): string {
    if (!stack) return '';
    const stackLines = stack.split('\n');

    // stack[1] = "    at FunctionName (file:line:col)"
    const callerLine = stackLines[1] || '';
    return callerLine.trim();
  }

  log(payload: LogPayload | string, context?: string) {
    const { msg, ctx, trc } = this.buildMessage(payload, context);
    this.logger.info(`${msg}${trc ? ` | trace: ${trc}` : ''}`, {
      context: ctx,
    });
  }

  error(payload: LogPayload | string, trace?: any, context?: string) {
    const { msg, ctx } = this.buildMessage(payload, context);

    let stackInfo = '';
    if (trace instanceof Error) {
      stackInfo = this.getStackInfo(trace.stack);
    } else if (typeof trace === 'string') {
      stackInfo = this.getStackInfo(trace);
    }

    this.logger.error(`${msg}${stackInfo ? ` | at: ${stackInfo}` : ''}`, {
      context: ctx,
    });
  }

  warn(payload: LogPayload | string, context?: string) {
    const { msg, ctx, trc } = this.buildMessage(payload, context);
    this.logger.warn(`${msg}${trc ? ` | trace: ${trc}` : ''}`, {
      context: ctx,
    });
  }

  debug(payload: LogPayload | string, context?: string) {
    const { msg, ctx, trc } = this.buildMessage(payload, context);
    this.logger.debug(`${msg}${trc ? ` | trace: ${trc}` : ''}`, {
      context: ctx,
    });
  }
}
