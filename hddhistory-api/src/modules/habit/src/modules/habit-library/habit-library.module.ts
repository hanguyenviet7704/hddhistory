import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import { AuthModule } from 'src/modules/user/src/modules/auth/auth.module';

import { HabitLibraryController } from './habit-library.controller';
import { HabitLibraryService } from './habit-library.service';
import { HabitLibraryRepository } from './repository/habit-library.repository';
import { HabitLibrary, HabitLibrarySchema } from './schema/habit-library.schema';
import { HabitContentModule } from '../../shared/habit-content.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HabitLibrary.name, schema: HabitLibrarySchema },
    ]),
    AuthModule,
    HabitContentModule,
  ],
  controllers: [HabitLibraryController],
  providers: [HabitLibraryService, HabitLibraryRepository],
  exports: [HabitLibraryService, HabitLibraryRepository],
})
export class HabitLibraryModule {}
