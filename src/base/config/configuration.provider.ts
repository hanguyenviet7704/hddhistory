import { Configuration } from './configuration';

export const ConfigurationProvider = {
  provide: Configuration,
  useValue: new Configuration(),
};
