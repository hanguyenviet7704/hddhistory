# Repository Guidelines

## Project Structure & Module Organization

- `src/app.module.ts` wires the NestJS app; `src/main.ts` sets global pipes/filters, versioning, Swagger, and CORS.
- `src/base/` holds shared infrastructure (filters, guards, interceptors, middleware, DB config, logging, validation, i18n) consumed via the `@base/*` path alias.
- `src/modules/` contains feature modules: `chat`, `courses` (course flows), `file`, `user`, and `socket`. Keep DTOs/providers/controller logic close to each module.
- For a normal business submodule directory, such as `src/modules/<feature>/<submodule>/` or `src/modules/<feature>/src/modules/<submodule>/`, the minimum expected layer set is `*.module.ts`, `service`, `controller`, and request/response `dto`. If the submodule owns persistence, it must also include `repository` plus `schema`/`entity`/`model`. If the submodule defines domain-specific types, keep `enum` and `interface` locally unless they are intentionally shared through `src/utils/`.
- Special/support modules such as `socket`, transport adapters, AI or orchestration-only modules, or other modules without normal HTTP/business/persistence responsibilities may omit non-applicable layers. Treat those as explicit exceptions justified by module responsibility, not the default structure for feature modules or a shortcut for convenience.
- Layer responsibilities for a normal business submodule are explicit: `controller` handles transport concerns only (route decorators, auth guards, params/body/query mapping, response handoff), `service` owns business rules and orchestration, `repository` owns all database reads/writes and query construction, `dto` defines validated API contracts, `schema`/`entity`/`model` defines persistence shape, and local `enum`/`interface` defines module domain types.
- Do not access the database outside the repository layer. `service` must not call `InjectModel`, `InjectRepository`, raw SQL, ORM models, query builders, or schema/entity persistence methods directly. If business logic needs data, call a repository method instead.
- Keep `service` focused on business logic, cross-repository orchestration, permission/domain checks, transaction boundaries, and domain-specific error handling. Do not move HTTP decorator concerns, request parsing, or persistence query details into `service`.
- Keep `controller` thin: receive validated DTOs, call the appropriate service method, and return the result. Do not place business branching, persistence logic, or ad hoc data-mapping pipelines in controllers except small transport-level adaptation.
- Every new or modified API-facing DTO field should declare validation and Swagger metadata. Use `@ApiProperty` or `@ApiPropertyOptional` with a meaningful `description`, realistic `example`, and correct `required`, `enum`, `type`, or `default` metadata when applicable. Prefer composing DTOs with Nest mapped types such as `PartialType`, `PickType`, and `OmitType` instead of duplicating fields.
- Keep `schema`/`entity`/`model` files limited to persistence mapping and storage-level defaults. Keep `enum` and `interface` near the module when they are domain-specific; move them to `src/utils/` only after they are genuinely shared across multiple modules.
- `src/utils/` centralizes shared DTOs, interfaces, enums, and types (`@utils/*` alias). Avoid duplicating shapes inside modules.
- Build artifacts land in `dist/`; API contract lives in `swagger-spec.json`; runtime logs write to `logs/`. Environment templates: `.env.example`, `google-service.example.json`.

## Build, Test, and Development Commands

- `npm install` once to pull dependencies (Nest CLI is included).
- `npm run start:dev` runs the API with watch mode; routes are prefixed with `/api`.
- `npm run start` starts without watch; `npm run build` compiles to `dist/`; `npm run start:prod` executes the compiled bundle (`dist/main.js`).
- `npm run lint` applies ESLint with import-ordering and TypeScript rules (auto-fix enabled in the script).

## Coding Style & Naming Conventions

- Prettier enforces 2-space indentation, 80-char width, semicolons, single quotes, trailing commas, and compact arrow params.
- Name files/folders in kebab-case; follow Nest suffixes (`*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.dto.ts`).
- Use path aliases from `tsconfig.json` (`@base/*`, `@utils/*`) instead of deep relatives; honor ESLint import order (builtin → external → internal → parent/sibling → object/type) with blank lines between groups.
- Prefer typed params/returns; `any` is permitted but keep scope narrow. Unused vars are warned unless prefixed with `_`.

## Testing Guidelines

- A Jest runner is not wired yet; add `*.spec.ts` alongside modules when introducing risky logic. Mock external services (DB, Firebase) and exercise validation through `BaseValidationPipe`.
- Once Jest is added, run `npm test -- --runInBand` locally and aim for coverage on controllers/services that touch auth, chat flow, and socket gateways.

## Commit & Pull Request Guidelines

- Mirror existing history: `feature-<ticket> short phrase` (or `fix/ chore` variants). Keep messages imperative and scoped.
- PRs should include a concise summary, linked HDDHISTORY ticket, commands executed (`npm run lint`, tests if present), and evidence for API changes (Swagger update, sample request/response, or curl snippet).
- Keep PRs small and single-purpose; document schema/config changes (ENV keys, CORS origins, Firebase settings) in the description.

## Security & Configuration Tips

- Do not commit secrets: use `.env.example` and `google-service.example.json` as templates; keep real `.env` and `google-service.json` local or in a secrets manager.
- Ports/CORS origins are set in `src/main.ts`; coordinate with frontend teams before changing.
- Logs write to `logs/` (managed by Winston rotation). Avoid logging sensitive data beyond what is needed for debugging.
