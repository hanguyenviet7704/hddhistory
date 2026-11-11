import { PartialType } from '@nestjs/swagger';

import { CreateHabitLibraryDto } from './create-habit-library.dto';

export class UpdateHabitLibraryDto extends PartialType(CreateHabitLibraryDto) {}
