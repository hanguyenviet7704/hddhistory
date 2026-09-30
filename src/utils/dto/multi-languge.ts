import {
  registerDecorator,
  ValidationArguments,
  ValidationOptions,
} from 'class-validator';

export function IsMultiLangString(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isMultiLangString',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: any) {
          if (!value || typeof value !== 'object' || Array.isArray(value)) {
            return false;
          }

          const entries = Object.entries(value);

          if (!entries.length) return false;

          const isStringMap = entries.every(([k, v]) => {
            return (
              typeof k === 'string' &&
              typeof v === 'string'
            );
          });

          if (!isStringMap) return false;

          return entries.some(
            ([, v]) => typeof v === 'string' && v.trim().length > 0,
          );
        },

        defaultMessage(args: ValidationArguments) {
          return `${args.property} must be an object with string:string pairs and at least one non-empty value (e.g. { "en": "Hello" })`;
        },
      },
    });
  };
}
