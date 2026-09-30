import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsNotEmpty, IsNumber, IsObject, Min } from 'class-validator';

import { ExerciseDragDropDto } from '../excercises/drag-drop.dto';
import { ExerciseMultipleChoiceDto } from '../excercises/multiple-choice.dto';
import { ExerciseRecordDto } from '../excercises/record.dto';
import { ExerciseSingleChoiceNoCorrectAnswerDto } from '../excercises/single-choice-no-correct-answer.dto';
import { ExerciseSingleChoiceDto } from '../excercises/single-choice.dto';

export class VideoQuestionDto {
  @ApiProperty({
    required: true,
    example: 45,
    description: 'Trigger timestamp in seconds',
  })
  @IsNotEmpty()
  @IsNumber()
  @Min(0)
  atSecond: number;

  @IsObject()
  @ApiProperty({
    type: ExerciseDragDropDto,
    example: ExerciseDragDropDto,
    required: true,
  })
  @Type(
    () =>
      ExerciseDragDropDto ||
      ExerciseSingleChoiceDto ||
      ExerciseMultipleChoiceDto ||
      ExerciseSingleChoiceNoCorrectAnswerDto ||
      ExerciseRecordDto,
  )
  exercise:
    | ExerciseDragDropDto
    | ExerciseSingleChoiceDto
    | ExerciseMultipleChoiceDto
    | ExerciseSingleChoiceNoCorrectAnswerDto
    | ExerciseRecordDto;
}
