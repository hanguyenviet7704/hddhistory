import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

/// Lưu thẻ lúc app đang tiếng Việt, đổi app sang tiếng Anh, mở lại thẻ trong
/// Thư viện → tiêu đề ra tiếng Anh còn phần nội dung vẫn tiếng Việt (báo lỗi
/// on-device 2026-09-10, ảnh "How writing and print reshaped the mind" kèm ba
/// gạch đầu dòng tiếng Việt).
///
/// Nguyên nhân: tiêu đề là `BaseMultiLanguage` nên đọc lại theo ngôn ngữ hiện
/// tại mỗi lần mở, còn recap bị chốt thành MỘT chuỗi tại thời điểm lưu. Dữ
/// liệu gốc (`block.data.content`) vốn có đủ 5 thứ tiếng — chỗ hỏng là gọi
/// `.text` (chỉ lấy ngôn ngữ đang bật) TRƯỚC khi đem đi lưu.
LearningItemEntity _takeawayItem() => const LearningItemEntity(
  id: 't1',
  type: LearningItemType.theory,
  documents: [
    DocumentEntity(
      id: 1,
      document: [
        ContentDocumentEntity(
          id: 1,
          type: ContentDocumentType.text,
          data: DocumentDataEntity(
            content: BaseMultiLanguage(
              vi: '🔑 ĐIỀU CẦN NHỚ\nChữ viết tạo ra "trí nhớ ngoài".',
              en: '🔑 KEY TAKEAWAY\nWriting created an "external memory".',
              zh: '🔑 重點\n文字創造了「外部記憶」。',
              ja: '🔑 ポイント\n文字は「外部記憶」を生んだ。',
              ko: '🔑 핵심\n문자는 "외부 기억"을 만들었다.',
            ),
          ),
        ),
      ],
    ),
  ],
);

void main() {
  test('recap giữ đủ 5 ngôn ngữ, không chốt theo ngôn ngữ đang bật', () {
    final recap = _takeawayItem().takeawaySummary;

    expect(recap.vi, 'Chữ viết tạo ra "trí nhớ ngoài".');
    expect(recap.en, 'Writing created an "external memory".');
    expect(recap.zh, '文字創造了「外部記憶」。');
    expect(recap.ja, '文字は「外部記憶」を生んだ。');
    expect(recap.ko, '문자는 "외부 기억"을 만들었다.');
  });

  test('bỏ dòng 🔑 và thẻ HTML ở TỪNG ngôn ngữ, không riêng ngôn ngữ đang bật', () {
    const item = LearningItemEntity(
      id: 't2',
      type: LearningItemType.theory,
      documents: [
        DocumentEntity(
          id: 1,
          document: [
            ContentDocumentEntity(
              id: 1,
              type: ContentDocumentType.text,
              data: DocumentDataEntity(
                content: BaseMultiLanguage(
                  vi: '🔑 GHI NHỚ<br/>Dòng một.<br/>Dòng hai.',
                  en: '🔑 REMEMBER<br/>Line one.<br/>Line two.',
                ),
              ),
            ),
          ],
        ),
      ],
    );

    expect(item.takeawaySummary.vi, 'Dòng một.\nDòng hai.');
    expect(item.takeawaySummary.en, 'Line one.\nLine two.');
  });

  test('ngôn ngữ chưa dịch thì để RỖNG, không độn ngôn ngữ khác vào', () {
    const item = LearningItemEntity(
      id: 't3',
      type: LearningItemType.theory,
      documents: [
        DocumentEntity(
          id: 1,
          document: [
            ContentDocumentEntity(
              id: 1,
              type: ContentDocumentType.text,
              data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Only English.')),
            ),
          ],
        ),
      ],
    );

    expect(item.takeawaySummary.en, 'Only English.');
    // Rỗng ở đây là ĐÚNG: `.text` lúc đọc sẽ tự lùi về `en`. Độn sẵn tiếng Anh
    // vào ô `vi` sẽ khiến thẻ kẹt tiếng Anh vĩnh viễn kể cả sau khi nội dung
    // được dịch bổ sung.
    expect(item.takeawaySummary.vi, '');
  });
}
