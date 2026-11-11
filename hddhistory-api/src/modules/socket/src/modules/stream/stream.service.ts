import { Injectable } from '@nestjs/common';

@Injectable()
export class StreamService {
  async streamMessage(
    message: string,
    onChunk: (chunk: string) => void,
    onEnd: () => void,
  ) {
    const words = message.split(' ');

    for (const word of words) {
      await new Promise(resolve => setTimeout(resolve, 2000)); // giả lập delay
      onChunk(word + ' ');
    }

    onEnd();
  }
}
