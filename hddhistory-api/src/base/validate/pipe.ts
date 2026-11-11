import {
  ArgumentMetadata,
  BadRequestException,
  Injectable,
  PipeTransform,
  ValidationPipe,
  ValidationError,
} from '@nestjs/common';

@Injectable()
export class BaseValidationPipe
  extends ValidationPipe
  implements PipeTransform<any>
{
  constructor() {
    super({
      whitelist: true,
      transform: true,
      exceptionFactory: (errors: ValidationError[] | any) => {
        let message = 'Validation failed';

        if (Array.isArray(errors) && errors.length > 0) {
          const extracted = extractErrorMessage(errors);
          if (extracted) {
            message = extracted;
          }
        } else if (typeof errors === 'string') {
          message = errors;
        } else if (errors?.message) {
          message = errors.message;
        }

        return new BadRequestException(message);
      },
    });
  }

  async transform(value: any, metadata: ArgumentMetadata) {
    return super.transform(value, metadata);
  }
}

function extractErrorMessage(errors: ValidationError[]): string {
  for (const error of errors) {
    if (error.constraints) {
      // Lấy message đầu tiên từ constraints
      return Object.values(error.constraints)[0];
    }
    if (error.children && error.children.length > 0) {
      // Đệ quy vào children
      const childMessage = extractErrorMessage(error.children);
      if (childMessage) {
        return childMessage;
      }
    }
  }
  return null;
}
