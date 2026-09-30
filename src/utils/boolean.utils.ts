import { Transform } from 'class-transformer';

export const ToBoolean = () =>
  Transform(({ obj, key }) => {
    return obj[key] === 'true' ? true : obj[key] === 'false' ? false : obj[key];
  });
