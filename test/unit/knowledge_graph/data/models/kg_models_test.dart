
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// JSON dưới đây chép nguyên văn từ phản hồi thật của
/// `GET /api/v1/knowledge-graph/entities/ngo_quyen` (Neo4j đã nạp bộ dữ liệu
/// lịch sử Việt Nam). Mục đích là chốt hợp đồng giữa API và model Dart: sai
/// khác về hình dạng ở đây là kiểu lỗi chỉ lộ ra lúc chạy thật.
const String _kProfileJson = '''
{
  "id": "ngo_quyen",
  "type": "figure",
  "name": "Ngô Quyền",
  "description": "Đánh bại quân Nam Hán trên sông Bạch Đằng năm 938, chấm dứt hơn 1000 năm Bắc thuộc, xưng vương lập nhà Ngô.",
  "period": {
    "name": "Ngô – Đinh – Tiền Lê",
    "start": "939",
    "end": "1009",
    "id": "p03_ngo_dinh_tienle"
  },
  "outgoing": [
    {
      "relation": "led",
      "entity": {
        "id": "tran_bach_dang_938",
        "type": "event",
        "name": "Trận Bạch Đằng năm 938",
        "description": "Ngô Quyền dùng kế cắm cọc đánh bại thủy quân Nam Hán, kết thúc thời kỳ Bắc thuộc."
      }
    }
  ],
  "incoming": [
    {
      "relation": "succeeded",
      "entity": {
        "id": "duong_tam_kha",
        "type": "figure",
        "name": "Dương Tam Kha",
        "description": "Con trai Dương Đình Nghệ, em vợ Ngô Quyền."
      }
    }
  ],
  "samePeriod": [
    {"id": "dinh_bo_linh", "type": "figure", "name": "Đinh Bộ Lĩnh"}
  ],
  "sources": [
    {"id": "dvsktt", "title": "Đại Việt sử ký toàn thư"}
  ]
}
''';

void main() {
  group('KgEntityProfileModel', () {
    test('giải mã đúng phản hồi thật của endpoint hồ sơ', () {
      final model = KgEntityProfileModel.fromJson(
        jsonDecode(_kProfileJson) as Map<String, dynamic>,
      );
      final entity = model.toEntity();

      expect(entity.id, 'ngo_quyen');
      expect(entity.type, KgEntityType.figure);
      expect(entity.period?.name, 'Ngô – Đinh – Tiền Lê');
      expect(entity.period?.start, '939');
      expect(entity.outgoing.single.relation, 'led');
      expect(entity.outgoing.single.entity.type, KgEntityType.event);
      expect(entity.incoming.single.entity.name, 'Dương Tam Kha');
      expect(entity.samePeriod.single.id, 'dinh_bo_linh');
      expect(entity.sources.single.title, 'Đại Việt sử ký toàn thư');
      // `note` không có trong phản hồi này — phải là null chứ không phải ''.
      expect(entity.note, isNull);
    });

    test('loại thực thể lạ rơi về unknown thay vì ném lỗi', () {
      final model = KgEntityProfileModel.fromJson({
        'id': 'x',
        'type': 'dynasty_artifact_we_have_not_shipped_yet',
        'name': 'X',
      });

      expect(model.toEntity().type, KgEntityType.unknown);
    });

    test('quan hệ thiếu đầu kia bị loại bỏ thay vì dựng thẻ rỗng', () {
      final model = KgEntityProfileModel.fromJson({
        'id': 'x',
        'type': 'figure',
        'name': 'X',
        'outgoing': [
          {'relation': 'led'},
          {
            'relation': 'founded',
            'entity': {'id': 'y', 'type': 'organization', 'name': 'Y'},
          },
        ],
      });

      final outgoing = model.toEntity().outgoing;
      expect(outgoing, hasLength(1));
      expect(outgoing.single.entity.id, 'y');
    });
  });

  group('KgRelatedEntityModel', () {
    test('giải mã hops và via của endpoint thực thể liên quan', () {
      final model = KgRelatedEntityModel.fromJson({
        'id': 'ngo_xuong_van',
        'type': 'figure',
        'name': 'Ngô Xương Văn',
        'description': 'Con Ngô Quyền, giành lại ngôi báu từ tay Dương Tam Kha.',
        'hops': 1,
        'via': ['child_of'],
      });

      final entity = model.toEntity();
      expect(entity.hops, 1);
      expect(entity.via, ['child_of']);
      expect(kgRelationLabel(entity.via.single), 'là con của');
    });
  });

  group('kgRelationLabel', () {
    test('mã quan hệ chưa có nhãn hiện ở dạng đọc được', () {
      expect(kgRelationLabel('moved_capital_to'), 'dời đô về');
      expect(kgRelationLabel('some_new_relation'), 'some new relation');
    });
  });

  group('kgPeriodRange', () {
    test('ghép hai đầu mốc, chịu được đầu trống', () {
      expect(
        kgPeriodRange(const KgPeriod(id: 'p', name: 'Nhà Trần', start: '1225', end: '1400')),
        '1225 – 1400',
      );
      expect(
        kgPeriodRange(const KgPeriod(id: 'p', name: 'x', start: '1225', end: '')),
        '1225',
      );
      expect(kgPeriodRange(const KgPeriod(id: 'p', name: 'x')), '');
    });
  });
}
