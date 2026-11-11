import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';

import { CreateNotificationCampaignDto } from './notification-campaign.dto';

/**
 * `deeplinkParams` là một Record, không phải mảng — và `each: true` của
 * class-validator CHỈ lặp Array/Set/Map. Đặt nó lên một object thuần thì object
 * bị validate NGUYÊN KHỐI như một string, nên MỌI request có field này đều 400.
 *
 * Spec của `sanitizeDeeplinkParams` không bắt được lỗi đó: nó test hàm thuần,
 * còn lỗi nằm ở biên validate. Đây là chỗ bù.
 */
describe('CreateNotificationCampaignDto · deeplinkParams', () => {
  const base = {
    name: 'test',
    copies: [{ locale: 'en', title: 't', body: 'b' }],
    deeplink: 'paywall',
    sendMode: 'now',
  };

  const errorsFor = (deeplinkParams?: unknown) => {
    const dto = plainToInstance(CreateNotificationCampaignDto, {
      ...base,
      ...(deeplinkParams === undefined ? {} : { deeplinkParams }),
    });

    return validateSync(dto as object)
      .filter(error => error.property === 'deeplinkParams')
      .flatMap(error => Object.values(error.constraints ?? {}));
  };

  it('nhận object rỗng — admin gửi {} khi người soạn không chọn gì', () => {
    expect(errorsFor({})).toEqual([]);
  });

  it('nhận một tham số hợp lệ', () => {
    expect(errorsFor({ variant: 'full' })).toEqual([]);
  });

  it('vắng mặt cũng hợp lệ', () => {
    expect(errorsFor(undefined)).toEqual([]);
  });

  it('từ chối mảng và chuỗi — không phải Record', () => {
    expect(errorsFor(['full']).length).toBeGreaterThan(0);
    expect(errorsFor('full').length).toBeGreaterThan(0);
  });
});
