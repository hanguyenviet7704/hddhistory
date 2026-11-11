import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

OnboardingPackageEntity pkg(String code, String branch, int order) => OnboardingPackageEntity(
  code: code, branchCode: branch, order: order,
  problemLabel: BaseMultiLanguage(vi: 'p $code'), desireLabel: BaseMultiLanguage(vi: 'd $code'),
);

OnboardingTaxonomyEntity taxonomy() => OnboardingTaxonomyEntity(
  branches: [
    for (final b in ['CX', 'LV', 'TD', 'QH', 'HT']) OnboardingBranchEntity(code: b, label: BaseMultiLanguage(vi: b)),
  ],
  packages: [
    for (var i = 1; i <= 6; i++) pkg('CX-$i', 'CX', i),
    for (var i = 1; i <= 7; i++) pkg('LV-$i', 'LV', i),
    for (var i = 1; i <= 3; i++) pkg('TD-$i', 'TD', i),
    for (var i = 1; i <= 5; i++) pkg('QH-$i', 'QH', i),
    for (var i = 1; i <= 5; i++) pkg('HT-$i', 'HT', i),
  ],
);

List<String> codes(List<OnboardingPackageEntity> list) => list.map((p) => p.code).toList();
int countPrefix(List<OnboardingPackageEntity> list, String prefix) => list.where((p) => p.branchCode == prefix).length;

void main() {
  group('problemOptions (câu 2)', () {
    test('1 nhánh → toàn bộ gói của nhánh, theo order', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['LV']);
      expect(codes(r), ['LV-1', 'LV-2', 'LV-3', 'LV-4', 'LV-5', 'LV-6', 'LV-7']);
    });

    test('2 nhánh → 5/5, xen kẽ theo thứ tự chọn', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['LV', 'CX']);
      expect(r.length, 10);
      expect(countPrefix(r, 'LV'), 5);
      expect(countPrefix(r, 'CX'), 5);
      expect(codes(r).take(2), ['LV-1', 'CX-1']);
    });

    test('3 nhánh → 4/3/3', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['CX', 'LV', 'QH']);
      expect([countPrefix(r, 'CX'), countPrefix(r, 'LV'), countPrefix(r, 'QH')], [4, 3, 3]);
    });

    test('4 nhánh → 3/3/2/2; 5 nhánh → 2 mỗi nhánh', () {
      final r4 = OnboardV2SelectionRules.problemOptions(taxonomy(), ['CX', 'LV', 'QH', 'HT']);
      expect([countPrefix(r4, 'CX'), countPrefix(r4, 'LV'), countPrefix(r4, 'QH'), countPrefix(r4, 'HT')], [3, 3, 2, 2]);
      final r5 = OnboardV2SelectionRules.problemOptions(taxonomy(), ['CX', 'LV', 'TD', 'QH', 'HT']);
      expect(r5.length, 10);
      expect(['CX', 'LV', 'TD', 'QH', 'HT'].map((b) => countPrefix(r5, b)), everyElement(2));
    });

    test('nhánh ít gói (TD có 3) thì nhánh khác lấp cho đủ 10', () {
      final r = OnboardV2SelectionRules.problemOptions(taxonomy(), ['TD', 'LV']);
      expect(r.length, 10);
      expect(countPrefix(r, 'TD'), 3);
      expect(countPrefix(r, 'LV'), 7);
    });

    test('không chọn nhánh → rỗng', () {
      expect(OnboardV2SelectionRules.problemOptions(taxonomy(), []), isEmpty);
    });
  });

  group('desireOptions (câu 3)', () {
    test('1 gói → mọi mong muốn cùng nhánh', () {
      final r = OnboardV2SelectionRules.desireOptions(taxonomy(), ['CX-2'], seed: 1);
      expect(codes(r), ['CX-1', 'CX-2', 'CX-3', 'CX-4', 'CX-5', 'CX-6']);
    });

    test('2 gói → 2 tương ứng + 1 random cùng nhánh cho mỗi gói (≤4), ổn định theo seed', () {
      final a = OnboardV2SelectionRules.desireOptions(taxonomy(), ['LV-1', 'CX-2'], seed: 7);
      final b = OnboardV2SelectionRules.desireOptions(taxonomy(), ['LV-1', 'CX-2'], seed: 7);
      expect(codes(a), codes(b));
      expect(a.length, 4);
      expect(codes(a).take(2), ['LV-1', 'CX-2']);
      expect(a[2].branchCode, 'LV');
      expect(a[3].branchCode, 'CX');
      expect(a[2].code, isNot('LV-1'));
      expect(a[3].code, isNot('CX-2'));
    });

    test('2 gói cùng nhánh → random không trùng nhau và không trùng gói đã chọn', () {
      final r = OnboardV2SelectionRules.desireOptions(taxonomy(), ['TD-1', 'TD-2'], seed: 3);
      expect(codes(r).toSet().length, r.length);
      expect(r.length, 3); // TD chỉ còn TD-3 để random
    });

    test('≥3 gói → chỉ các mong muốn tương ứng, giữ thứ tự chọn', () {
      final r = OnboardV2SelectionRules.desireOptions(taxonomy(), ['HT-2', 'LV-1', 'CX-6'], seed: 1);
      expect(codes(r), ['HT-2', 'LV-1', 'CX-6']);
    });
  });

  test('seedFor không phụ thuộc thứ tự và ổn định', () {
    expect(OnboardV2SelectionRules.seedFor(['A', 'B']), OnboardV2SelectionRules.seedFor(['B', 'A']));
    expect(OnboardV2SelectionRules.seedFor(['A', 'B']), isNot(OnboardV2SelectionRules.seedFor(['A', 'C'])));
  });
}
