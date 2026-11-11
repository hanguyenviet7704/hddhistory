import {
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';

import { PaymentPlatform } from 'src/modules/payment/enum/payment.enum';

import { PaywallConfigDto } from './dto/paywall-config.dto';
import {
  PAYWALL_CONFIG_PARAMETER_KEY,
  REMOTE_CONFIG_SEED_PUBLISHED_BY,
} from './paywall-config.constants';
import { PaywallConfigService } from './paywall-config.service';

function makeValidConfig(
  overrides: Partial<PaywallConfigDto> = {},
): PaywallConfigDto {
  const content = {
    en: { subheading: 'Sub', heading: 'Head', benefits: [] },
  };

  return {
    schemaVersion: 1,
    enableLessonLock: true,
    lessonLock: 1,
    autoOpen: { enabled: true, sessionRolloutPercent: 50 },
    saleStrategy: {
      defaultUser: {
        content,
        products: [{ appleProductId: 'sku_apple', googleProductId: 'sku_google' }],
      },
      saleEvent: {
        enabled: false,
        content,
        products: [],
      },
    },
    ...overrides,
  } as PaywallConfigDto;
}

/**
 * In-memory fake standing in for `paywall_configs` -- mirrors exactly the
 * invariant `PaywallConfigRepository.publishNewVersion` enforces for real
 * (new row = max(version) + 1, exactly one row ever marked current) so
 * these service-level tests exercise the real versioning/restore contract
 * without a database.
 */
function makeService(opts: {
  productLookup?: (where: {
    platform: PaymentPlatform;
    productId: string;
  }) => any;
  remoteConfigValue?: string | null;
  user?: { id?: string; email?: string };
} = {}) {
  const rows: any[] = [];
  let productLookup =
    opts.productLookup ??
    (({ platform, productId }: any) => ({ platform, productId, isActive: true }));

  const paywallConfigRepository: any = {
    findCurrent: jest.fn(async () => rows.find(r => r.isCurrent) ?? null),
    findByVersion: jest.fn(
      async (version: number) => rows.find(r => r.version === version) ?? null,
    ),
    findAllVersions: jest.fn(async () =>
      [...rows].sort((a, b) => b.version - a.version),
    ),
    countAll: jest.fn(async () => rows.length),
    publishNewVersion: jest.fn(async (config: any, publishedBy?: string) => {
      const prevVersion = rows.reduce((max, r) => Math.max(max, r.version), 0);
      rows.forEach(r => {
        if (r.isCurrent) r.isCurrent = null;
      });
      const next = {
        id: `row-${prevVersion + 1}`,
        config,
        version: prevVersion + 1,
        publishedAt: new Date('2026-07-28T00:00:00.000Z'),
        publishedBy,
        isCurrent: true,
      };
      rows.push(next);
      return next;
    }),
    getRemoteConfigTemplate: jest.fn(async () => ({
      parameters:
        opts.remoteConfigValue === null
          ? {}
          : {
              [PAYWALL_CONFIG_PARAMETER_KEY]: {
                defaultValue: {
                  value: opts.remoteConfigValue ?? JSON.stringify(makeValidConfig()),
                },
              },
            },
    })),
  };

  const productRepository: any = {
    findOne: jest
      .fn()
      .mockImplementation(
        async (where: { platform: PaymentPlatform; productId: string }) =>
          productLookup(where),
      ),
  };

  const requestService: any = {
    user: opts.user ?? { id: 'admin-1', email: 'admin@meup.training' },
  };

  // LogicSale collaborators, stubbed neutral: no purchases recorded, and the
  // segment filter passes everything through (an item with no segmentIds is
  // for everyone — the pass-through mirrors that default).
  const purchaseRepository: any = {
    logicSaleStats: jest.fn().mockResolvedValue([]),
    paywallExperimentStats: jest.fn().mockResolvedValue([]),
  };

  // Body-experiment funnel source: empty by default, so a test that does not
  // care about the readout sees zeroed arms rather than an undefined call.
  const userEventRepository: any = {
    countUsersByParam: jest.fn().mockResolvedValue({}),
  };

  const segmentService: any = {
    filterItemsForViewer: jest
      .fn()
      .mockImplementation(async (items: unknown[]) => items),
  };

  const service = new PaywallConfigService(
    paywallConfigRepository,
    productRepository,
    purchaseRepository,
    segmentService,
    userEventRepository,
    requestService,
  );

  return {
    service,
    paywallConfigRepository,
    productRepository,
    purchaseRepository,
    userEventRepository,
    segmentService,
    requestService,
    rows,
    setProductLookup: (fn: typeof productLookup) => {
      productLookup = fn;
    },
  };
}

describe('PaywallConfigService.validateShape', () => {
  it('passes for a fully valid config', () => {
    const { service } = makeService();
    expect(service.validateShape(makeValidConfig())).toEqual([]);
  });

  it('reports missing required top-level keys', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    delete (dto as any).schemaVersion;
    delete (dto as any).enableLessonLock;
    delete (dto as any).autoOpen;

    const errors = service.validateShape(dto);
    const fields = errors.map(e => e.field);

    expect(fields).toContain('schemaVersion');
    expect(fields).toContain('enableLessonLock');
    expect(fields).toContain('autoOpen');
  });

  it('rejects an empty products array on defaultUser', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    dto.saleStrategy.defaultUser.products = [];

    const errors = service.validateShape(dto);

    expect(errors).toContainEqual(
      expect.objectContaining({ field: 'saleStrategy.defaultUser.products' }),
    );
  });


  it('flags a product entry with neither appleProductId nor googleProductId', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    dto.saleStrategy.defaultUser.products = [{}];

    const errors = service.validateShape(dto);

    expect(errors).toContainEqual(
      expect.objectContaining({
        field: 'saleStrategy.defaultUser.products[0]',
      }),
    );
  });
});

describe('PaywallConfigService.validateShape — compactProducts', () => {
  it('accepts compactProducts being absent (the client falls back to products)', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    expect(dto.saleStrategy.defaultUser.compactProducts).toBeUndefined();

    expect(service.validateShape(dto)).toEqual([]);
  });

  it('accepts an empty compactProducts array — also a fallback, not a mistake', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    dto.saleStrategy.defaultUser.compactProducts = [];

    expect(service.validateShape(dto)).toEqual([]);
  });

  it('flags a compactProducts row that names no SKU', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    dto.saleStrategy.defaultUser.compactProducts = [{}];

    expect(service.validateShape(dto)).toContainEqual(
      expect.objectContaining({
        field: 'saleStrategy.defaultUser.compactProducts[0]',
      }),
    );
  });


  it('holds compactProducts to the same iap_products existence guard as products', async () => {
    const { service } = makeService({
      productLookup: ({ platform, productId }) =>
        productId === 'sku_compact_missing'
          ? null
          : { platform, productId, isActive: true },
    });
    const dto = makeValidConfig();
    dto.saleStrategy.defaultUser.compactProducts = [
      { appleProductId: 'sku_compact_missing' },
    ];

    await expect(service.updateConfig(dto)).rejects.toMatchObject({
      response: {
        errors: expect.arrayContaining([
          expect.objectContaining({
            field: 'saleStrategy.defaultUser.compactProducts[0].appleProductId',
            message: expect.stringContaining('does not exist'),
          }),
        ]),
      },
    });
  });
});

describe('PaywallConfigService.validateShape — lessonLock count', () => {
  it('requires lessonLock when enableLessonLock is true', () => {
    const { service } = makeService();
    const dto = makeValidConfig();
    delete (dto as any).lessonLock;

    expect(service.validateShape(dto)).toContainEqual(
      expect.objectContaining({ field: 'lessonLock' }),
    );
  });

  it('allows lessonLock = 0 (a deliberately fully locked course)', () => {
    const { service } = makeService();

    expect(service.validateShape(makeValidConfig({ lessonLock: 0 }))).toEqual([]);
  });

  it('does not require lessonLock when the gate is off', () => {
    const { service } = makeService();
    const dto = makeValidConfig({ enableLessonLock: false });
    delete (dto as any).lessonLock;

    expect(service.validateShape(dto)).toEqual([]);
  });
});

describe('PaywallConfigService.validateShape — sale event window and audience', () => {
  const enabledSaleEvent = (overrides: Record<string, unknown> = {}) =>
    makeValidConfig({
      saleStrategy: {
        ...makeValidConfig().saleStrategy,
        saleEvent: {
          enabled: true,
          campaignId: 'black-friday',
          startAtUtc: '2026-11-27T00:00:00.000Z',
          endAtUtc: '2026-12-01T00:00:00.000Z',
          appliesTo: ['defaultUser'],
          content: { en: { heading: 'Sale' } },
          products: [{ appleProductId: 'sku_apple' }],
          ...overrides,
        },
      },
    } as any);

  it('passes for a fully specified enabled campaign', () => {
    const { service } = makeService();

    expect(service.validateShape(enabledSaleEvent())).toEqual([]);
  });

  it('requires both bounds when enabled', () => {
    const { service } = makeService();
    const dto = enabledSaleEvent();
    delete (dto.saleStrategy.saleEvent as any).startAtUtc;
    delete (dto.saleStrategy.saleEvent as any).endAtUtc;

    const fields = service.validateShape(dto).map(e => e.field);

    expect(fields).toContain('saleStrategy.saleEvent.startAtUtc');
    expect(fields).toContain('saleStrategy.saleEvent.endAtUtc');
  });

  it('rejects an unparseable bound', () => {
    const { service } = makeService();

    expect(
      service.validateShape(enabledSaleEvent({ startAtUtc: 'next friday' })),
    ).toContainEqual(
      expect.objectContaining({ field: 'saleStrategy.saleEvent.startAtUtc' }),
    );
  });

  it('rejects an end that is not after the start', () => {
    const { service } = makeService();

    expect(
      service.validateShape(
        enabledSaleEvent({ endAtUtc: '2026-11-27T00:00:00.000Z' }),
      ),
    ).toContainEqual(
      expect.objectContaining({ field: 'saleStrategy.saleEvent.endAtUtc' }),
    );
  });

  it('rejects an empty audience list, which targets nobody', () => {
    const { service } = makeService();

    expect(service.validateShape(enabledSaleEvent({ appliesTo: [] }))).toContainEqual(
      expect.objectContaining({ field: 'saleStrategy.saleEvent.appliesTo' }),
    );
  });

  it('leaves a disabled campaign alone — no window, no audience, no errors', () => {
    const { service } = makeService();

    // makeValidConfig's saleEvent is disabled and has neither bound nor audience.
    expect(service.validateShape(makeValidConfig())).toEqual([]);
  });
});

describe('PaywallConfigService.updateConfig — product-existence guard', () => {
  it('rejects with a 400 listing the offending id when a product is missing from iap_products', async () => {
    const { service } = makeService({ productLookup: () => null });

    await expect(
      service.updateConfig(makeValidConfig()),
    ).rejects.toMatchObject({
      response: {
        errors: expect.arrayContaining([
          expect.objectContaining({
            field: 'saleStrategy.defaultUser.products[0].appleProductId',
            message: expect.stringContaining('does not exist'),
          }),
        ]),
      },
    });
  });

  it('rejects with a 400 when a referenced product exists but is inactive', async () => {
    const { service } = makeService({
      productLookup: ({ platform, productId }) => ({
        platform,
        productId,
        isActive: false,
      }),
    });

    await expect(service.updateConfig(makeValidConfig())).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('never publishes (no new MySQL row) when a product reference fails validation', async () => {
    const { service, paywallConfigRepository } = makeService({
      productLookup: () => null,
    });

    await expect(service.updateConfig(makeValidConfig())).rejects.toBeInstanceOf(
      BadRequestException,
    );

    expect(paywallConfigRepository.publishNewVersion).not.toHaveBeenCalled();
  });

  it('only looks up each distinct (platform, productId) pair once', async () => {
    const { service, productRepository } = makeService();
    // sku_apple is referenced by both defaultUser and the impression rule.
    await service.updateConfig(makeValidConfig());

    const appleLookups = productRepository.findOne.mock.calls.filter(
      ([where]: any) => where.productId === 'sku_apple',
    );
    expect(appleLookups.length).toBe(1);
  });
});

describe('PaywallConfigService.updateConfig — versioning (MySQL, append-only)', () => {
  it('publishes version 1 with no prior rows', async () => {
    const { service } = makeService();

    const result = await service.updateConfig(makeValidConfig());

    expect(result.version).toBe(1);
    expect(result.publishedBy).toBe('admin@meup.training');
  });

  it('increments the version on each successive publish instead of mutating', async () => {
    const { service, rows } = makeService();

    const first = await service.updateConfig(makeValidConfig({ schemaVersion: 1 }));
    const second = await service.updateConfig(makeValidConfig({ schemaVersion: 2 }));

    expect(first.version).toBe(1);
    expect(second.version).toBe(2);
    // Both rows retained -- append-only, nothing was overwritten.
    expect(rows).toHaveLength(2);
    expect(rows.find(r => r.version === 1)?.config.schemaVersion).toBe(1);
  });

  it('marks exactly the latest published row as current', async () => {
    const { service } = makeService();

    await service.updateConfig(makeValidConfig({ schemaVersion: 1 }));
    await service.updateConfig(makeValidConfig({ schemaVersion: 2 }));

    const versions = await service.getVersions();
    const current = versions.filter(v => v.isCurrent);

    expect(current).toHaveLength(1);
    expect(current[0].version).toBe(2);
  });
});

describe('PaywallConfigService.restore', () => {
  it('throws NotFoundException for a version that does not exist', async () => {
    const { service } = makeService();

    await expect(service.restore(99)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('re-publishes an older version as a new, later version without mutating history', async () => {
    const { service, rows } = makeService();

    await service.updateConfig(makeValidConfig({ schemaVersion: 1 }));
    await service.updateConfig(makeValidConfig({ schemaVersion: 2 }));

    const restored = await service.restore(1);

    expect(restored.version).toBe(3);
    expect(restored.config.schemaVersion).toBe(1);
    // v1 and v2 rows are both still present, untouched.
    expect(rows).toHaveLength(3);
    expect(rows.find(r => r.version === 1)?.config.schemaVersion).toBe(1);
    expect(rows.find(r => r.version === 2)?.config.schemaVersion).toBe(2);
  });

  it('re-validates referenced products and refuses to restore a version whose SKU is now inactive', async () => {
    const { service, setProductLookup } = makeService();

    await service.updateConfig(makeValidConfig());

    // The SKU that v1 referenced has since been deactivated in iap_products.
    setProductLookup(({ platform, productId }) => ({
      platform,
      productId,
      isActive: false,
    }));

    await expect(service.restore(1)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('never publishes a new row when restore validation fails', async () => {
    const { service, paywallConfigRepository, setProductLookup } = makeService();

    await service.updateConfig(makeValidConfig());
    paywallConfigRepository.publishNewVersion.mockClear();
    setProductLookup(() => null);

    await expect(service.restore(1)).rejects.toBeInstanceOf(BadRequestException);
    expect(paywallConfigRepository.publishNewVersion).not.toHaveBeenCalled();
  });
});

describe('PaywallConfigService — first-read Remote Config cutover seed', () => {
  it('seeds version 1 from Remote Config when paywall_configs is empty', async () => {
    const seedValue = JSON.stringify(makeValidConfig({ schemaVersion: 7 }));
    const { service, paywallConfigRepository } = makeService({
      remoteConfigValue: seedValue,
    });

    const result = await service.getConfig();

    expect(result.version).toBe(1);
    expect(result.publishedBy).toBe(REMOTE_CONFIG_SEED_PUBLISHED_BY);
    expect(result.config.schemaVersion).toBe(7);
    expect(paywallConfigRepository.getRemoteConfigTemplate).toHaveBeenCalledTimes(1);
  });

  it('does not reseed once a row exists', async () => {
    const { service, paywallConfigRepository } = makeService();

    await service.getConfig();
    await service.getConfig();

    expect(paywallConfigRepository.getRemoteConfigTemplate).toHaveBeenCalledTimes(1);
  });

  it('getMobileConfig returns the raw config object, not the admin envelope', async () => {
    const { service } = makeService();

    const result = await service.getMobileConfig();

    expect(result).toEqual(makeValidConfig());
    expect((result as any).version).toBeUndefined();
    expect((result as any).publishedAt).toBeUndefined();
  });

  it('throws NotFoundException when the table is empty and Remote Config has no value either', async () => {
    const { service } = makeService({ remoteConfigValue: null });

    await expect(service.getConfig()).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws InternalServerErrorException when rows exist but none is marked current', async () => {
    const { service, rows } = makeService();
    rows.push({
      id: 'row-1',
      config: makeValidConfig(),
      version: 1,
      publishedAt: new Date(),
      publishedBy: 'admin@meup.training',
      isCurrent: null,
    });

    await expect(service.getConfig()).rejects.toBeInstanceOf(
      InternalServerErrorException,
    );
  });
});

/**
 * The body A/B split. These are the assertions the run's validity rests on: a
 * viewer must stay in one arm, the arms must come out the SIZE the config
 * asked for, and everyone the server cannot honestly place must be left out
 * rather than quietly parked in `benefits` and counted.
 */
describe('PaywallConfigService — body experiment assignment', () => {
  const rows = [{ label: 'Bài học', free: '1/ngày', premium: 'Không giới hạn' }];

  function configWithRun(
    overrides: Partial<{
      enabled: boolean;
      key: string;
      comparisonPercent: number;
    }> = {},
    locales: Record<string, unknown> = { en: { comparison: rows }, vi: { comparison: rows } },
  ) {
    const base = makeValidConfig();
    return {
      ...base,
      bodyExperiment: {
        key: 'paywall_body_test',
        enabled: true,
        comparisonPercent: 50,
        ...overrides,
      },
      saleStrategy: {
        ...base.saleStrategy,
        defaultUser: {
          ...base.saleStrategy.defaultUser,
          content: { ...base.saleStrategy.defaultUser.content, ...locales },
        },
      },
    } as PaywallConfigDto;
  }

  async function seeded(config: PaywallConfigDto) {
    const made = makeService();
    await made.service.updateConfig(config);
    return made.service;
  }

  it('keeps one viewer in the same arm across resolves', async () => {
    const service = await seeded(configWithRun());

    const first = await service.resolveLogicSaleFor('user-42', 'vi');
    const again = await service.resolveLogicSaleFor('user-42', 'vi');

    expect(first.experiment.inExperiment).toBe(true);
    expect(again.experiment.variant).toBe(first.experiment.variant);
    expect(first.experiment.key).toBe('paywall_body_test');
  });

  it('splits close to the configured percentage over many viewers', async () => {
    const service = await seeded(configWithRun({ comparisonPercent: 50 }));

    let comparison = 0;
    const total = 2000;
    for (let index = 0; index < total; index++) {
      const { experiment } = await service.resolveLogicSaleFor(
        `user-${index}`,
        'vi',
      );
      if (experiment.variant === 'comparison') comparison++;
    }

    // A hash that skews would still be deterministic; only the SIZE of the
    // arms catches it, so that is what is asserted.
    expect(comparison / total).toBeGreaterThan(0.45);
    expect(comparison / total).toBeLessThan(0.55);
  });

  it('honours 0% and 100% as one-armed wind-downs', async () => {
    const none = await seeded(configWithRun({ comparisonPercent: 0 }));
    const all = await seeded(configWithRun({ comparisonPercent: 100 }));

    const a = await none.resolveLogicSaleFor('user-7', 'vi');
    const b = await all.resolveLogicSaleFor('user-7', 'vi');

    expect(a.experiment.variant).toBe('benefits');
    expect(b.experiment.variant).toBe('comparison');
  });

  it('leaves out a viewer whose own locale has no comparison rows', async () => {
    const service = await seeded(
      configWithRun({}, { en: { comparison: rows } }),
    );

    const { experiment } = await service.resolveLogicSaleFor('user-42', 'ko');

    expect(experiment.inExperiment).toBe(false);
    expect(experiment.reason).toBe('locale_without_comparison');
    expect(experiment.variant).toBe('benefits');
  });

  it('leaves out an unidentifiable viewer', async () => {
    const service = await seeded(configWithRun());

    const { experiment } = await service.resolveLogicSaleFor('', 'vi');

    expect(experiment.inExperiment).toBe(false);
    expect(experiment.reason).toBe('anonymous_viewer');
  });

  it('falls back to the config bodyVariant when no run is enabled', async () => {
    const service = await seeded(
      configWithRun({ enabled: false }) as PaywallConfigDto,
    );

    const { experiment } = await service.resolveLogicSaleFor('user-42', 'vi');

    expect(experiment.inExperiment).toBe(false);
    expect(experiment.reason).toBe('no_run');
  });

  it('refuses to publish an enabled run with no comparison rows at all', () => {
    const { service } = makeService();

    const errors = service.validateShape(
      configWithRun({}, { en: {}, vi: {} }) as PaywallConfigDto,
    );

    expect(errors.some(e => e.field === 'bodyExperiment.enabled')).toBe(true);
  });
});
