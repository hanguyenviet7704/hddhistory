import { Injectable, NotFoundException } from '@nestjs/common';
import { I18nContext, I18nService } from 'nestjs-i18n/dist';

import { RequestService } from '@base/service/request.service';

import { CreateOnboardingDto } from './dto/create-onboarding.dto';
import { UpdateOnboardingScenarioBranchingDto } from './dto/update-onboarding-scenario-branching.dto';
import { UpdateOnboardingDto } from './dto/update-onboarding.dto';
import { IOnboardingScenarioBranching } from './interface/onboarding-scenario-branching.interface';
import { IOnboarding } from './interface/onboarding.interface';
import { OnboardingScenarioBranchingRepository } from './repository/onboarding-scenario-branching.repository';
import { OnboardingRepository } from './repository/onboarding.repository';
import { Onboarding } from './schema/onboarding';

@Injectable()
export class OnboardingService {
  constructor(
    private readonly onboardingRepository: OnboardingRepository,
    private readonly onboardingScenarioBranchingRepository: OnboardingScenarioBranchingRepository,
    private readonly requestService: RequestService,
    private readonly i18n: I18nService,
  ) {}

  private get user() {
    return this.requestService.user;
  }
  get lang(): string {
    return I18nContext.current()?.lang ?? 'en';
  }

  async create(createOnboardingDto: CreateOnboardingDto): Promise<Onboarding> {
    // create roadmap
    return await this.onboardingRepository.create(
      {
        ...createOnboardingDto,
      } as IOnboarding,
      this.user,
    );
  }

  async find() {
    const check = await this.onboardingRepository.findOne({});

    if (!check) {
      await this.onboardingRepository.create({
        intro: [],
        age: [],
        gender: [],
        categoryWantToMaster: [],
        learningGoal: [],
        learningStruggles: [],
        comfortableLearningTime: [],
        dailyLearningGoal: [],
        timeToBecomeSkilled: [],
        welcome: {},
        motivationOne: {},
        motivationTwo: {},
        motivationThree: {},
        loading: {},
        paths: [],
        copy: [],
      } as unknown as IOnboarding);
    }

    return this.onboardingRepository.findOne({});
  }

  async findScenarioBranching() {
    const check =
      await this.onboardingScenarioBranchingRepository.findOne({});

    if (!check) {
      await this.onboardingScenarioBranchingRepository.create({
        entrySceneId: '',
        scenes: [],
      } as IOnboardingScenarioBranching);
    }

    return this.onboardingScenarioBranchingRepository.findOne({});
  }

  async updateScenarioBranching(
    id: string,
    updateOnboardingScenarioBranchingDto: UpdateOnboardingScenarioBranchingDto,
  ) {
    const onboarding =
      await this.onboardingScenarioBranchingRepository.findOne({ _id: id });
    if (!onboarding)
      throw new NotFoundException(
        this.i18n.t('error.ONBOARDING.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const update = await this.onboardingScenarioBranchingRepository.updateOne(
      { _id: id },
      {
        ...updateOnboardingScenarioBranchingDto,
      } as IOnboardingScenarioBranching,
      this.user,
    );

    return update;
  }

  async findOne(id: string): Promise<Onboarding> {
    const Onboarding = await this.onboardingRepository.findOne({ _id: id });
    if (!Onboarding)
      throw new NotFoundException(
        this.i18n.t('error.ONBOARDING.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    return Onboarding;
  }

  async update(id: string, updateOnboardingDto: UpdateOnboardingDto) {
    const onboarding = await this.onboardingRepository.findOne({ _id: id });
    if (!onboarding)
      throw new NotFoundException(
        this.i18n.t('error.ONBOARDING.NOT_FOUND', {
          lang: this.lang,
        }),
      );

    const update = await this.onboardingRepository.updateOne(
      { _id: id },
      {
        ...updateOnboardingDto,
      },
      this.user,
    );

    return update;
  }

  async remove(id: string) {
    const res = await this.onboardingRepository.deleteOne({ _id: id });
    return res;
  }
}
