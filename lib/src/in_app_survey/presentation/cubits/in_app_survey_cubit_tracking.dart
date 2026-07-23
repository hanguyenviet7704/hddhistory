part of '../../in_app_survey.dart';

extension _InAppSurveyCubitTracking on InAppSurveyCubit {
  static const _source = 'home';

  void _trackPopupView(InAppSurveyStep step) {
    AppService.instance.appTrackingService.trackInAppSurveyPopupView(
      source: _source,
      step: step.trackingName,
    );
  }

  void _trackPopupClose(InAppSurveyStep step) {
    AppService.instance.appTrackingService.trackInAppSurveyPopupClose(
      source: _source,
      step: step.trackingName,
    );
  }

  void _trackEmojiClick(InAppSurveyBranchEntity branch) {
    AppService.instance.appTrackingService.trackInAppSurveyEmojiClick(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
    );
  }

  void _trackClosedQuestionView(InAppSurveyBranchEntity branch) {
    AppService.instance.appTrackingService.trackInAppSurveyClosedQuestionView(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
    );
  }

  void _trackClosedOptionClick(InAppSurveyBranchEntity branch, List<String> selectedOptionIds) {
    AppService.instance.appTrackingService.trackInAppSurveyClosedOptionClick(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
      selectedOptionIds: selectedOptionIds,
    );
  }

  void _trackClosedContinueClick(InAppSurveyBranchEntity branch, List<String> selectedOptionIds) {
    AppService.instance.appTrackingService.trackInAppSurveyClosedContinueClick(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
      selectedOptionIds: selectedOptionIds,
    );
  }

  void _trackOpenQuestionView(InAppSurveyBranchEntity branch, List<String> selectedOptionIds) {
    AppService.instance.appTrackingService.trackInAppSurveyOpenQuestionView(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
      selectedOptionIds: selectedOptionIds,
    );
  }

  void _trackSendClick(InAppSurveyBranchEntity branch, InAppSurveyResponseEntity response) {
    AppService.instance.appTrackingService.trackInAppSurveySendClick(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
      selectedOptionIds: response.selectedOptionIds,
      feedbackEmpty: response.feedback.isEmpty,
    );
    // Spec-named submit event, fired alongside the existing send-click telemetry.
    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.inappSurveySubmit,
      parameters: {
        'source': _source,
        'branch_id': branch.id,
        'branch_index': branch.index,
      },
    );
  }

  void _trackSendSuccess(InAppSurveyBranchEntity branch, InAppSurveyResponseEntity response) {
    AppService.instance.appTrackingService.trackInAppSurveySendSuccess(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
      selectedOptionIds: response.selectedOptionIds,
      feedbackEmpty: response.feedback.isEmpty,
    );
  }

  void _trackSendFailure(InAppSurveyBranchEntity branch, InAppSurveyResponseEntity response, AppException exception) {
    AppService.instance.appTrackingService.trackInAppSurveySendFailure(
      source: _source,
      branchId: branch.id,
      branchIndex: branch.index,
      selectedOptionIds: response.selectedOptionIds,
      feedbackEmpty: response.feedback.isEmpty,
      errorType: exception.runtimeType.toString(),
    );
  }
}
