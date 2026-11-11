import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

class _FakeInAppSurveyApi implements InAppSurveyApi {
  Map<String, dynamic>? lastBody;

  @override
  Future<BaseResponse<void>> createInAppSurveyResponse(Map<String, dynamic> body) async {
    lastBody = Map<String, dynamic>.from(body);
    return const BaseResponse(status: true);
  }

  @override
  Future<BaseResponse<InAppSurveyConfigModel>> getInAppSurveyConfig() {
    throw UnimplementedError();
  }
}

class _FakeInAppSurveyLocalDataSource implements InAppSurveyLocalDataSource {
  @override
  Future<void> cacheInAppSurveyConfig(InAppSurveyConfigModel model) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<InAppSurveyConfigModel?> getCachedInAppSurveyConfig() async => null;
}

void main() {
  group('InAppSurveyRepository', () {
    test('posts branch id, selected option ids, and trimmed feedback fields only', () async {
      final api = _FakeInAppSurveyApi();
      final repository = InAppSurveyRepository(api, _FakeInAppSurveyLocalDataSource());

      final result = await repository
          .createInAppSurveyResponse(
            const InAppSurveyResponseEntity(
              branchId: 'branch-1',
              selectedOptionIds: ['option-1'],
              feedback: '',
            ),
          )
          .run();

      expect(result.isRight(), isTrue);
      expect(api.lastBody, {
        'branchId': 'branch-1',
        'selectedOptionIds': ['option-1'],
        'feedback': '',
      });
      expect(api.lastBody, isNot(contains('configKey')));
      expect(api.lastBody, isNot(contains('closedAnswerIds')));
      expect(api.lastBody, isNot(contains('openAnswer')));
    });
  });
}
