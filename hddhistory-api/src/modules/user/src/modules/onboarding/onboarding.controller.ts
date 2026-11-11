import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { UpdateOnboardingDto } from './dto/update-onboarding.dto';
import { OnboardingService } from './onboarding.service';

@ApiTags('ONBOARDINGS')
@Controller({ path: 'onboardings', version: '1' })
export class OnboardingController {
  constructor(private readonly svc: OnboardingService) {}

  // @Post('')
  // register(@Body() dto: CreateOnboardingDto) {
  //   return this.svc.create(dto);
  // }

  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateOnboardingDto) {
    return this.svc.update(id, dto);
  }

  @Get('')
  find() {
    return this.svc.find();
  }

  // @Get(':id')
  // findOne(@Param('id') id: string) {
  //   return this.svc.findOne(id);
  // }

  // @Delete(':id')
  // remove(@Param('id') id: string) {
  //   return this.svc.remove(id);
  // }
}
