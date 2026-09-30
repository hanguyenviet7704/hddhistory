import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Query,
  UseGuards,
  Put,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

import { Public } from '@base/decorator/public';
import { AuthGuard } from '@base/guard/auth.guard';

import { CreateQuoteDto } from './dto/create-quote.dto';
import { GetListQuoteDto } from './dto/get-list-quote.dto';
import { UpdateQuoteDto } from './dto/update-quote.dto';
import { QuoteService } from './quote.service';

@ApiTags('COURSES-QUOTES')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller({ path: 'courses-quotes', version: '1' })
export class QuoteController {
  constructor(
    private readonly quoteService: QuoteService,
    private readonly configService: ConfigService,
  ) {}

  @Post()
  create(@Body() createQuoteDto: CreateQuoteDto) {
    return this.quoteService.create(createQuoteDto);
  }

  @Get()
  findAll(@Query() getListQuoteDto: GetListQuoteDto) {
    return this.quoteService.findAll(getListQuoteDto);
  }

  @Public()
  @Get('random')
  findRandom() {
    return this.quoteService.findRandom();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.quoteService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateQuoteDto: UpdateQuoteDto) {
    return this.quoteService.update(id, updateQuoteDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.quoteService.remove(id);
  }
}
