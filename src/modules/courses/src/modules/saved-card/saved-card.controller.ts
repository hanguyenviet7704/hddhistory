import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { AuthGuard } from '@base/guard/auth.guard';

import { GetSavedCardsDto, SaveCardDto } from './dto/saved-card.dto';
import { SavedCardService } from './saved-card.service';

@ApiTags('COURSES-SAVED-CARD')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'saved-cards', version: '1' })
export class SavedCardController {
  constructor(private readonly svc: SavedCardService) {}

  @Get()
  getSaved(@Req() req: any, @Query() dto: GetSavedCardsDto) {
    return this.svc.getSaved(req.user?.id, dto);
  }

  @Get('/ids')
  getSavedIds(@Req() req: any) {
    return this.svc.getSavedIds(req.user?.id);
  }

  @Post()
  save(@Req() req: any, @Body() dto: SaveCardDto) {
    return this.svc.save(req.user?.id, dto);
  }

  @Delete('/:keypointId')
  remove(@Req() req: any, @Param('keypointId') keypointId: string) {
    return this.svc.remove(req.user?.id, keypointId);
  }
}
