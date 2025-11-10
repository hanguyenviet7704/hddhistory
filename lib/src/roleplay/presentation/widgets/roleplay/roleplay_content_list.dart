part of '../../../roleplay.dart';

class RoleplayContentList extends StatefulWidget {
  final SectionEntity section;

  const RoleplayContentList({super.key, required this.section});

  @override
  State<RoleplayContentList> createState() => _RoleplayContentListState();
}

class _RoleplayContentListState extends State<RoleplayContentList> {
  static const Duration _defaultDelay = Duration(seconds: 2);

  final ScrollController _scrollController = ScrollController();
  final Map<int, RoleplayAudioController> _audioControllers = {};

  late List<SectionContentEntity> _displayableContents;
  int _visibleCount = 0;
  bool _isSequencing = false;

  @override
  void initState() {
    super.initState();
    _configureContents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  @override
  void didUpdateWidget(RoleplayContentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.id != widget.section.id) {
      unawaited(_resetForNewSection());
    }
  }

  void _configureContents() {
    _displayableContents = widget.section.contents.where((c) => c.type != RoleplaySectionType.exercise).toList();
    _prepareAudioControllers();
  }

  Future<void> _resetForNewSection() async {
    await _disposeControllers();
    if (!mounted) return;
    setState(() {
      _visibleCount = 0;
      _displayableContents = widget.section.contents.where((c) => c.type != RoleplaySectionType.exercise).toList();
      _prepareAudioControllers();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  void _prepareAudioControllers() {
    _audioControllers.clear();

    for (var i = 0; i < _displayableContents.length; i++) {
      final content = _displayableContents[i];
      final String audioUrl = switch (content.type) {
        RoleplaySectionType.conversation => content.conversation.audio,
        RoleplaySectionType.leadingText => content.leadingText.audio,
        _ => '',
      };
      if (audioUrl.isNotEmpty) {
        _audioControllers[i] = RoleplayAudioController(audioUrl);
      }
    }
  }

  Future<void> _startSequence() async {
    if (_isSequencing) return;
    _isSequencing = true;

    try {
      while (mounted && _visibleCount < _displayableContents.length) {
        setState(() {
          _visibleCount++;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        await _waitBeforeNext();
      }
    } finally {
      _isSequencing = false;
    }
  }

  Future<void> _waitBeforeNext() async {
    final int currentIndex = _visibleCount - 1;
    if (currentIndex < 0 || currentIndex >= _displayableContents.length) return;

    final content = _displayableContents[currentIndex];
    final RoleplayAudioController? controller = _audioControllers[currentIndex];

    switch (content.type) {
      case RoleplaySectionType.conversation:
      case RoleplaySectionType.leadingText:
        if (controller != null && controller.hasAudio) {
          await controller.playAutoAndWait();
          return;
        }
        break;
      default:
        break;
    }

    await Future.delayed(_defaultDelay);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    unawaited(_disposeControllers());
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _disposeControllers() async {
    await Future.wait(_audioControllers.values.map((controller) => controller.dispose()));
    _audioControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayableContents.isEmpty || _visibleCount == 0) {
      return ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: _visibleCount,
      itemBuilder: (context, index) {
        if (index >= _displayableContents.length) return const SizedBox.shrink();
        final content = _displayableContents[index];
        final audioController = _audioControllers[index];

        return switch (content.type) {
          RoleplaySectionType.conversation => RoleplayConversationBubble(
            conversation: content.conversation,
            audioController: audioController,
          ),
          RoleplaySectionType.leadingText => RoleplayLeadingTextCard(
            leadingText: content.leadingText,
            audioController: audioController,
          ),
          RoleplaySectionType.hint => RoleplayHintCard(hint: content.hint),
          RoleplaySectionType.exercise => const SizedBox.shrink(),
        };
      },
      separatorBuilder: (context, index) => 16.verticalSpace,
    );
  }
}
