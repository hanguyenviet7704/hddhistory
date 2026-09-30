import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as admin from 'firebase-admin';
import { Repository } from 'typeorm';

import { FirebaseService } from '@base/config/firebase';
import { AbstractRepository } from '@base/database/mysql/abstract.repository';

import { PaywallConfigDto } from '../dto/paywall-config.dto';
import { PaywallConfig } from '../entity/paywall-config.entity';

/**
 * The only class in this module allowed to touch `paywall_configs` (MySQL)
 * or, for the one-time cutover seed, Firebase Remote Config. Every business
 * rule (shape validation, product-existence guard, seeding decision) lives in
 * `PaywallConfigService` and only ever calls the methods below.
 */
@Injectable()
export class PaywallConfigRepository extends AbstractRepository<PaywallConfig> {
  constructor(
    @InjectRepository(PaywallConfig) repository: Repository<PaywallConfig>,
    private readonly firebaseService: FirebaseService,
  ) {
    super(repository);
  }

  /** The row currently served live, or `null` if none is marked current. */
  findCurrent(): Promise<PaywallConfig | null> {
    return this.repository.findOne({ where: { isCurrent: true } });
  }

  findByVersion(version: number): Promise<PaywallConfig | null> {
    return this.repository.findOne({ where: { version } });
  }

  findAllVersions(): Promise<PaywallConfig[]> {
    return this.repository.find({ order: { version: 'DESC' } });
  }

  /** Whether `paywall_configs` has ever had a row published (cutover check). */
  async countAll(): Promise<number> {
    return this.repository.count();
  }

  /**
   * Append-only publish: inserts `config` as `version = (highest existing
   * version) + 1`, flips the previous current row (if any) to `isCurrent:
   * null`, and marks the new row `isCurrent: true` -- all inside one
   * transaction so a concurrent publish can never leave two rows marked
   * current (the `UQ_paywall_configs_is_current` unique key backs this up at
   * the DB level too) or reuse a version number.
   */
  publishNewVersion(
    config: PaywallConfigDto,
    publishedBy?: string,
  ): Promise<PaywallConfig> {
    return this.repository.manager.transaction(async manager => {
      const previous = await manager
        .createQueryBuilder(PaywallConfig, 'pc')
        .orderBy('pc.version', 'DESC')
        .limit(1)
        .setLock('pessimistic_write')
        .getOne();

      if (previous?.isCurrent) {
        await manager.update(PaywallConfig, previous.id, {
          isCurrent: null,
        });
      }

      const next = manager.create(PaywallConfig, {
        config,
        version: (previous?.version ?? 0) + 1,
        publishedAt: new Date(),
        publishedBy,
        isCurrent: true,
      });

      return manager.save(next);
    });
  }

  /**
   * Read-only Remote Config access, used for the first-read cutover seed
   * (`PaywallConfigService`'s `getConfig`/`getMobileConfig`).
   */
  getRemoteConfigTemplate(): Promise<admin.remoteConfig.RemoteConfigTemplate> {
    return this.firebaseService.remoteConfig().getTemplate();
  }

  /**
   * TRANSITIONAL: mirrors a published config back into Remote Config.
   *
   * MySQL is the source of truth, but every app already installed reads
   * Remote Config and will keep doing so until the release that switches to
   * `GET /paywall-config/mobile` is adopted. Without this mirror an operator
   * would publish, see "success", and change nothing for any real user —
   * silently worse than the behaviour we replaced.
   *
   * Delete this once the old app versions are drained.
   */
  async mirrorToRemoteConfig(
    key: string,
    config: unknown,
  ): Promise<void> {
    const remoteConfig = this.firebaseService.remoteConfig();
    const template = await remoteConfig.getTemplate();
    template.parameters[key] = {
      ...(template.parameters[key] ?? {}),
      defaultValue: { value: JSON.stringify(config) },
    };
    await remoteConfig.publishTemplate(template);
  }
}
