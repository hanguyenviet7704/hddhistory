part of '../../onboard_v2.dart';

/// Luật hiển thị câu 2 / câu 3 (design.md §3.2, §3.3). Thuần, không state.
abstract final class OnboardV2SelectionRules {
  static const int maxProblemOptions = 10;

  /// Câu 2: round-robin theo THỨ TỰ user chọn nhánh, mỗi nhánh lấy gói theo
  /// `order`, dừng ở 10. Cho ra đúng bảng 1→all, 2→5/5, 3→4/3/3, 4→3/3/2/2,
  /// 5→2×5; nhánh hết gói sớm thì nhánh khác lấp.
  static List<OnboardingPackageEntity> problemOptions(
    OnboardingTaxonomyEntity taxonomy,
    List<String> branchCodesInSelectionOrder,
  ) {
    if (branchCodesInSelectionOrder.isEmpty) return const [];
    final queues = [for (final code in branchCodesInSelectionOrder) taxonomy.packagesOf(code)];
    final cap = branchCodesInSelectionOrder.length == 1 ? queues.first.length : maxProblemOptions;
    final out = <OnboardingPackageEntity>[];
    var index = 0;
    while (out.length < cap && queues.any((q) => index < q.length)) {
      for (final q in queues) {
        if (out.length >= cap) break;
        if (index < q.length) out.add(q[index]);
      }
      index++;
    }
    return out;
  }

  /// Câu 3. n=1: mọi mong muốn cùng nhánh. n=2: 2 tương ứng + với mỗi gói 1
  /// random cùng nhánh (không trùng). n≥3: chỉ các mong muốn tương ứng.
  static List<OnboardingPackageEntity> desireOptions(
    OnboardingTaxonomyEntity taxonomy,
    List<String> packageCodesInSelectionOrder, {
    required int seed,
  }) {
    final selected = [
      for (final code in packageCodesInSelectionOrder) ?taxonomy.packageByCode(code),
    ];
    if (selected.isEmpty) return const [];

    if (selected.length == 1) {
      return taxonomy.packagesOf(selected.first.branchCode);
    }
    if (selected.length >= 3) return selected;

    final random = math.Random(seed);
    final out = [...selected];
    final taken = {for (final p in selected) p.code};
    for (final p in selected) {
      final pool = taxonomy.packagesOf(p.branchCode).where((x) => !taken.contains(x.code)).toList();
      if (pool.isEmpty) continue;
      final pick = pool[random.nextInt(pool.length)];
      taken.add(pick.code);
      out.add(pick);
    }
    return out;
  }

  /// Seed ổn định theo BỘ gói (không theo thứ tự) để quay lại màn không xáo.
  static int seedFor(List<String> packageCodes) {
    final sorted = [...packageCodes]..sort();
    return sorted.join('|').hashCode;
  }
}
