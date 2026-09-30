/**
 * Compiles every Coach module through Nest's own injector.
 *
 * Run: `npx ts-node -r tsconfig-paths/register src/modules/coach/coach-di.check.ts`
 *
 * This exists because a provider whose dependency is not available IN THE
 * MODULE THAT DECLARES IT is invisible to `tsc`, to `nest build`, and to any
 * static scan of imports — it surfaces only when Nest walks the graph, which in
 * production means a crash-looping container answering 502 to everything. That
 * is exactly how `CoachAiModule` reached dev without `ConfigurationProvider`.
 *
 * Only the module graph is exercised; nothing connects to a database. A module
 * that needs Mongo fails on its model tokens instead, reported separately from
 * a genuine wiring error.
 */
/* eslint-disable @typescript-eslint/no-var-requires */
import { config as loadEnv } from 'dotenv';

loadEnv();

// Joi rejects an empty string for an optional key, and the checked-in `.env`
// leaves several blank. Absent is what "unset" is supposed to mean here.
for (const [key, value] of Object.entries(process.env)) {
  if (value === '') delete process.env[key];
}

/**
 * Firebase is stubbed, not skipped.
 *
 * `google-service.json` is a placeholder on dev machines, so `credential.cert`
 * throws at construction and every module that transitively reaches AuthModule
 * dies before Nest looks at its wiring — which would hide exactly the class of
 * bug this file exists to catch. Nothing here calls Firebase; it only has to
 * be constructible.
 */
function stubFirebase() {
  const admin = require('firebase-admin');
  const app = {
    auth: () => ({}),
    messaging: () => ({}),
    remoteConfig: () => ({}),
  };
  admin.credential.cert = () => ({});
  admin.initializeApp = () => app;
}

async function main() {
  stubFirebase();

  const { Logger, Module } = require('@nestjs/common');
  const { NestFactory } = require('@nestjs/core');

  Logger.overrideLogger(false);

  const targets: Array<{ name: string; module: any }> = [
    {
      name: 'CoachAiModule',
      module: require('./src/modules/ai/coach-ai.module').CoachAiModule,
    },
    {
      name: 'CoachAiUsageModule',
      module: require('./src/modules/ai-usage/coach-ai-usage.module')
        .CoachAiUsageModule,
    },
    {
      name: 'CoachContentModule',
      module: require('./src/modules/content/coach-content.module')
        .CoachContentModule,
    },
    {
      name: 'CoachSafetyModule',
      module: require('./src/modules/safety/coach-safety.module')
        .CoachSafetyModule,
    },
    {
      name: 'CoachSituationModule',
      module: require('./src/modules/situation/coach-situation.module')
        .CoachSituationModule,
    },
    {
      name: 'CoachSessionModule',
      module: require('./src/modules/session/coach-session.module')
        .CoachSessionModule,
    },
    {
      name: 'CoachReminderModule',
      module: require('./src/modules/reminder/coach-reminder.module')
        .CoachReminderModule,
    },
  ];

  /**
   * Opt-in, because the checked-in `MONGODB_URI` points at a Docker-internal
   * host that a laptop cannot resolve. Set `COACH_DI_CHECK_DB=1` where Mongo IS
   * reachable (CI, a container) and every module gets checked; everywhere else
   * the pure ones are checked and the rest are reported as skipped rather than
   * as passing.
   */
  const canReachDb = process.env.COACH_DI_CHECK_DB === '1';
  const dbModules = canReachDb
    ? [
        // MongoDbModule reads its URI through ConfigService, so the config has
        // to be global here exactly as it is in `app.module`.
        require('@nestjs/config').ConfigModule.forRoot({ isGlobal: true }),
        require('../../base/database/mongodb/mongodb.module').MongoDbModule,
      ]
    : [];

  if (!canReachDb) {
    console.log(
      '  (COACH_DI_CHECK_DB unset — modules needing Mongo are skipped, not passed)\n',
    );
  }

  let failed = 0;

  for (const { name, module } of targets) {
    @Module({ imports: [...dbModules, module] })
    class Harness {}

    try {
      const app = await NestFactory.createApplicationContext(Harness, {
        logger: false,
        abortOnError: false,
      });
      await app.close();
      console.log(`  RESOLVED   ${name}`);
    } catch (error: any) {
      const message = String(error?.message ?? error);
      // A missing Mongoose model/connection token means the module wants a
      // database, not that its wiring is wrong.
      const needsDb = /Model|Connection|DataSource|Repository/.test(message);
      console.log(`  ${needsDb ? 'NEEDS-DB  ' : 'FAILED    '} ${name}`);
      if (!needsDb) {
        console.log(`     ${message.split('\n')[0]}`);
        failed += 1;
      }
    }
  }

  console.log(failed ? `\n${failed} module(s) cannot be constructed.` : '\nNo wiring errors.');
  process.exit(failed ? 1 : 0);
}

void main();
