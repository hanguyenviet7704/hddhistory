import { forwardRef, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { CourseModule } from 'src/modules/courses/src/modules/course/course.module';
import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { OnboardingTaxonomyImportService } from './onboarding-taxonomy-import.service';
import { OnboardingTaxonomyController } from './onboarding-taxonomy.controller';
import { OnboardingTaxonomyService } from './onboarding-taxonomy.service';
import { OnboardingBranchRepository } from './repository/onboarding-branch.repository';
import { OnboardingLabelRepository } from './repository/onboarding-label.repository';
import { OnboardingPackageRepository } from './repository/onboarding-package.repository';
import {
  OnboardingBranch,
  OnboardingBranchSchema,
} from './schema/onboarding-branch.schema';
import {
  OnboardingLabel,
  OnboardingLabelSchema,
} from './schema/onboarding-label.schema';
import {
  OnboardingPackage,
  OnboardingPackageSchema,
} from './schema/onboarding-package.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OnboardingBranch.name, schema: OnboardingBranchSchema },
      { name: OnboardingPackage.name, schema: OnboardingPackageSchema },
      { name: OnboardingLabel.name, schema: OnboardingLabelSchema },
    ]),
    forwardRef(() => AuthModule),
    forwardRef(() => CourseModule),
  ],
  controllers: [OnboardingTaxonomyController],
  providers: [
    OnboardingBranchRepository,
    OnboardingPackageRepository,
    OnboardingLabelRepository,
    OnboardingTaxonomyService,
    OnboardingTaxonomyImportService,
  ],
  exports: [
    OnboardingBranchRepository,
    OnboardingPackageRepository,
    OnboardingLabelRepository,
    OnboardingTaxonomyService,
  ],
})
export class OnboardingTaxonomyModule {}
