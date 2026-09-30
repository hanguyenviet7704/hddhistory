import * as Joi from 'joi';

export class Configuration {
  private readonly envConfig: { [key: string]: string };
  constructor() {
    this.envConfig = this.validateInput(
      Object.fromEntries(
        Object.entries(process.env).map(([key, value]) => [key, value ?? '']),
      ),
    );
  }
  private validateInput(env: { [key: string]: string }): {
    [key: string]: string;
  } {
    const schema = Joi.object({
      JWT_SECRET: Joi.string().required(),
      MONGODB_URI: Joi.string().required(),
      MAX_DEVICE: Joi.number().required(),
      JWT_EXPIRATION: Joi.string(),
      JWT_REFRESH_EXPIRATION: Joi.string(),
      MYSQL_HOST: Joi.string().required(),
      MYSQL_PORT: Joi.string().required(),
      MYSQL_USERNAME: Joi.string().required(),
      MYSQL_PASSWORD: Joi.string().required(),
      MYSQL_DB: Joi.string().required(),
      APPLE_ISSUER_ID: Joi.string().required(),
      APPLE_KEY_ID: Joi.string().required(),
      APPLE_BUNDLE_ID: Joi.string().required(),
      APPLE_KEY_PATH: Joi.string(),
      GOOGLE_WEBHOOK_AUDIENCE: Joi.string(),
      GOOGLE_WEBHOOK_SERVICE_ACCOUNT_EMAIL: Joi.string(),
      OUTPUT_PRACTICE_AI_HOST: Joi.string(),
      OUTPUT_PRACTICE_AI_SECRET_TOKEN: Joi.string(),
      GEMINI_API_KEY: Joi.string().optional(),
      GEMINI_MODEL: Joi.string().optional(),
      GEMINI_FALLBACK_MODELS: Joi.string().optional(),
      GEMINI_TIMEOUT_MS: Joi.string().optional(),
      AFFILIATE_ORDERS_SECRET_TOKEN: Joi.string(),
      APPLE_ASC_BUNDLE_ID: Joi.string().optional(),
      APPLE_ASC_KEY_PATH: Joi.string().optional(),
      APPLE_ASC_KEY_ID: Joi.string(),
      APPLE_ASC_ISSUER_ID: Joi.string(),
      APPLE_ASC_PRIVATE_KEY: Joi.string(),
      GOOGLE_PACKAGE_NAME: Joi.string(),
      DOWNLOAD_LINK_IP_SALT: Joi.string().optional(),
      // Đồ thị tri thức (module knowledge-graph). Để optional có chủ đích: mọi
      // môi trường đang chạy đều chưa có 3 biến này, bắt buộc sẽ làm app crash
      // ngay lúc khởi động. Thiếu cấu hình thì module trả 503 thay vì chết app.
      NEO4J_URI: Joi.string().optional(),
      NEO4J_USER: Joi.string().optional(),
      NEO4J_PASSWORD: Joi.string().optional(),
      NODE_ENV: Joi.string().valid('development', 'production').required(),
    }).unknown();
    const { error, value } = schema.validate(env);
    if (error) {
      throw new Error(`Configuration validation error: ${error.message}`);
    }
    return value;
  }
  get jwtSecret(): string {
    return this.envConfig.JWT_SECRET;
  }
  get mongodbUri(): string {
    return this.envConfig.MONGODB_URI;
  }
  get maxDevice(): string {
    return this.envConfig.MAX_DEVICE;
  }
  get getJwtExpiration(): string {
    return this.envConfig.JWT_EXPIRATION;
  }
  get getJwtRefreshExpiration(): string {
    return this.envConfig.JWT_REFRESH_EXPIRATION;
  }
  get getEnvironment(): string {
    return this.envConfig.NODE_ENV;
  }

  // Neo4j — đồ thị tri thức lịch sử
  get neo4jUri(): string {
    return this.envConfig.NEO4J_URI;
  }
  get neo4jUser(): string {
    return this.envConfig.NEO4J_USER;
  }
  get neo4jPassword(): string {
    return this.envConfig.NEO4J_PASSWORD;
  }
  get isNeo4jConfigured(): boolean {
    return Boolean(
      this.envConfig.NEO4J_URI &&
        this.envConfig.NEO4J_USER &&
        this.envConfig.NEO4J_PASSWORD,
    );
  }

  // Apple
  get getAppleKeyId(): string {
    return this.envConfig.APPLE_KEY_ID;
  }
  get getAppleIssuerId(): string {
    return this.envConfig.APPLE_ISSUER_ID;
  }
  get getAppleBundleId(): string {
    return this.envConfig.APPLE_BUNDLE_ID;
  }
  get getAppleKeyPath(): string {
    return this.envConfig.APPLE_KEY_PATH;
  }

  // Google webhook
  get getGoogleWebhookAudience(): string | undefined {
    return this.envConfig.GOOGLE_WEBHOOK_AUDIENCE;
  }
  get getGoogleWebhookServiceAccountEmail(): string | undefined {
    return this.envConfig.GOOGLE_WEBHOOK_SERVICE_ACCOUNT_EMAIL;
  }

  // Output practice AI
  get getOutputPracticeAiHost(): string | undefined {
    return this.envConfig.OUTPUT_PRACTICE_AI_HOST;
  }

  get getOutputPracticeAiSecretToken(): string | undefined {
    return this.envConfig.OUTPUT_PRACTICE_AI_SECRET_TOKEN;
  }

  // Gemini, used only by the learning-import feature (PDF/YouTube -> generated
  // lesson). Optional on purpose: without a key the rest of the API boots and
  // runs exactly as before, and the import endpoints reject with a clear
  // AI_NOT_CONFIGURED instead of the whole app refusing to start.
  //
  // ENV ONLY. A dev key briefly lived here as a constant (2026-08-10..11) so the
  // feature could be exercised on api-dev before it reached k8s config; a secret
  // in code is one every clone keeps forever, so the environment is now the only
  // source and each environment needs it set.
  get getGeminiApiKey(): string | undefined {
    return this.envConfig.GEMINI_API_KEY;
  }

  // Model id lives in env rather than in code so it can be swapped -- for cost,
  // quality, or a deprecation -- without a deploy.
  get getGeminiModel(): string | undefined {
    return this.envConfig.GEMINI_MODEL;
  }

  // Scene WRITING gets its own optional model: it runs once per practice (not
  // per turn) and carries the most multi-constraint prompt in the coach, so it
  // can afford a stronger model than the every-turn replies. Unset = same as
  // GEMINI_MODEL.
  get getGeminiSceneModel(): string | undefined {
    return this.envConfig.GEMINI_SCENE_MODEL;
  }

  // Comma-separated, best first: the models a busy one hands the turn on to,
  // for the mornings Gemini answers 503. Unset = the built-in pair of aliases;
  // the coach-config row overrides this, so a bad morning is fixable from the
  // admin page rather than from a deploy.
  get getGeminiFallbackModels(): string | undefined {
    return this.envConfig.GEMINI_FALLBACK_MODELS;
  }

  get getGeminiTimeoutMs(): string | undefined {
    return this.envConfig.GEMINI_TIMEOUT_MS;
  }

  // Affiliate orders API (POST /purchase/affiliateOrder) -- shared secret the
  // caller must send as `key_project` in the body. @Public() route, guarded
  // by AffiliateKeyGuard instead of JWT.
  get getAffiliateOrdersSecretToken(): string | undefined {
    return this.envConfig.AFFILIATE_ORDERS_SECRET_TOKEN;
  }

  // Salt for hashing click IPs on GET /r/:slug. Optional on purpose: when it
  // is unset the click is still recorded but with a NULL ip_hash, so unique
  // counts degrade instead of the server writing an unsalted hash -- IPv4
  // space is small enough that an unsalted digest is reversible by brute
  // force, which would make it personal data again.
  get getDownloadLinkIpSalt(): string | undefined {
    return this.envConfig.DOWNLOAD_LINK_IP_SALT;
  }

  // App Store Connect API (regional price sync, Part 2 of
  // plans/260727-voucher-paywall-config-affiliate/design.md). Distinct
  // credentials from APPLE_KEY_ID/APPLE_ISSUER_ID above -- those sign App
  // Store Server API tokens (purchase verification/webhooks); these sign App
  // Store Connect API tokens (reading the catalog: apps, subscription
  // groups/prices). Must be set before the price sync can run.
  /**
   * Bundle id used for App Store Connect *price* lookups.
   *
   * Deliberately separate from APPLE_BUNDLE_ID, which identifies the bundle a
   * webhook payload must be signed for and is therefore the environment's own
   * bundle. IAP products only exist under the production app record —
   * com.hddhistory.app.dev / .stg have no App Store Connect app at all — so a dev
   * deployment reusing APPLE_BUNDLE_ID would always fail with "No App Store
   * Connect app found". Falls back to APPLE_BUNDLE_ID when unset so production,
   * where the two coincide, needs no extra config.
   */
  get getAppleAscBundleId(): string {
    return this.envConfig.APPLE_ASC_BUNDLE_ID || this.envConfig.APPLE_BUNDLE_ID;
  }

  /** Path to a mounted App Store Connect .p8, as an alternative to
   * APPLE_ASC_PRIVATE_KEY -- mirrors APPLE_KEY_PATH for the Server API key. */
  get getAppleAscKeyPath(): string | undefined {
    return this.envConfig.APPLE_ASC_KEY_PATH;
  }

  get getAppleAscKeyId(): string | undefined {
    return this.envConfig.APPLE_ASC_KEY_ID;
  }
  get getAppleAscIssuerId(): string | undefined {
    return this.envConfig.APPLE_ASC_ISSUER_ID;
  }
  // Raw .p8 key content (not a file path) -- the API server has no
  // checked-in key file for these credentials.
  get getAppleAscPrivateKey(): string | undefined {
    return this.envConfig.APPLE_ASC_PRIVATE_KEY;
  }

  // Android package name for the Play Developer "monetization" API
  // (regional price sync). Distinct from any single `packageName` sent by a
  // client verify request -- this sync runs server-side with no client, so
  // the app id has to come from config.
  get getGooglePackageName(): string | undefined {
    return this.envConfig.GOOGLE_PACKAGE_NAME;
  }
}
