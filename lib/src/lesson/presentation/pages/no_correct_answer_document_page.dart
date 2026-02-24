part of '../../lesson.dart';

class NoCorrectAnswerDocumentPage extends StatefulWidget {
  final String groupId;

  const NoCorrectAnswerDocumentPage({
    super.key,
    required this.groupId,
  });

  @override
  State<NoCorrectAnswerDocumentPage> createState() => _NoCorrectAnswerDocumentPageState();
}

class _NoCorrectAnswerDocumentPageState extends State<NoCorrectAnswerDocumentPage> {
  NoCorrectAnswerDocumentGroupResolved? _resolvedGroup;

  @override
  void initState() {
    super.initState();

    final currentQuestion = context.read<ChoiceCubit>().state.question;
    _resolvedGroup = resolveNoCorrectAnswerDocumentGroupById(
      question: currentQuestion,
      groupId: widget.groupId,
    );

    if (_resolvedGroup == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pop(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedGroup = _resolvedGroup;

    return Scaffold(
      body: SafeArea(
        child: resolvedGroup == null
            ? const SizedBox.shrink()
            : ListView(
                padding: EdgeInsets.only(bottom: 16.h),
                children: [
                  if (resolvedGroup.documents.isNotEmpty) DocumentWidget(documents: resolvedGroup.documents),
                ],
              ),
      ),
      bottomNavigationBar: resolvedGroup == null
          ? null
          : SafeArea(
              top: false,
              child: _buildBottomButton(context),
            ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return ExerciseContinueButton(
      onPressed: () => context.pop(true),
      text: context.text.common.kContinue,
      isEnabled: true,
    );
  }
}
