part of '../../../roleplay.dart';

class RoleplayContentList extends StatefulWidget {
  final SectionEntity section;

  const RoleplayContentList({super.key, required this.section});

  @override
  State<RoleplayContentList> createState() => _RoleplayContentListState();
}

class _RoleplayContentListState extends State<RoleplayContentList> {
  static const Duration _defaultDelay = Duration(seconds: 2);

  late GlobalKey<AnimatedListState> _listKey;
  final ScrollController _scrollController = ScrollController();
  final Map<int, RoleplayAudioController> _audioControllers = {};
  final List<int> _visibleIndexes = [];

  late List<SectionContentEntity> _displayableContents;
  bool _isSequencing = false;

  @override
  void initState() {
    super.initState();
    _listKey = GlobalKey<AnimatedListState>();
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
    _visibleIndexes.clear();
  }

  Future<void> _resetForNewSection() async {
    await _disposeControllers();
    if (!mounted) return;
    setState(() {
      _listKey = GlobalKey<AnimatedListState>();
      _displayableContents = widget.section.contents.where((c) => c.type != RoleplaySectionType.exercise).toList();
      _prepareAudioControllers();
      _visibleIndexes.clear();
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
      while (mounted && _visibleIndexes.length < _displayableContents.length) {
        _appendNextIndex();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        await _waitBeforeNext();
      }
    } finally {
      _isSequencing = false;
    }
  }

  Future<void> _waitBeforeNext() async {
    if (_visibleIndexes.isEmpty) return;

    final int currentIndex = _visibleIndexes.last;
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

  void _appendNextIndex() {
    final newIndex = _visibleIndexes.length;
    if (newIndex >= _displayableContents.length) return;
    _visibleIndexes.add(newIndex);
    if (_listKey.currentState != null) {
      _listKey.currentState!.insertItem(newIndex, duration: const Duration(milliseconds: 250));
    }
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

  bool _isSamePerson(ConversationEntity conversation, ConversationEntity? nextConversation) {
    if (nextConversation == null) return false;
    return nextConversation.name == conversation.name;
  }

  double _getBottomPadding(int index, int contentIndex) {
    if (index == _visibleIndexes.length - 1) return 0;
    final content = _displayableContents[index];
    if (content.type != RoleplaySectionType.conversation) return 16.h;
    final nextConversation = contentIndex < _displayableContents.length - 1 ? _displayableContents[contentIndex + 1].conversation : null;
    if (_isSamePerson(content.conversation, nextConversation)) return 0;
    return 16.h;
  }

  @override
  Widget build(BuildContext context) {
    if (_displayableContents.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
      );
    }

    return AnimatedList(
      key: _listKey,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 16.h, top: 24.h),
      initialItemCount: _visibleIndexes.length,
      itemBuilder: (context, index, animation) {
        if (index >= _visibleIndexes.length) return const SizedBox.shrink();
        final contentIndex = _visibleIndexes[index];
        if (contentIndex >= _displayableContents.length) return const SizedBox.shrink();
        final content = _displayableContents[contentIndex];
        final previousConversation = contentIndex > 0 ? _displayableContents[contentIndex - 1].conversation : null;
        final audioController = _audioControllers[contentIndex];

        final Widget child = switch (content.type) {
          RoleplaySectionType.conversation => RoleplayConversationBubble(
            conversation: content.conversation,
            previousConversation: previousConversation,
            audioController: audioController,
          ),
          RoleplaySectionType.leadingText => RoleplayLeadingTextCard(
            leadingText: content.leadingText,
            audioController: audioController,
          ),
          RoleplaySectionType.hint => RoleplayHintCard(hint: content.hint),
          RoleplaySectionType.exercise => const SizedBox.shrink(),
        };

        return SizeTransition(
          sizeFactor: animation,
          child: Padding(
            padding: EdgeInsets.only(bottom: _getBottomPadding(index, contentIndex)),
            child: child,
          ),
        );
      },
    );
  }
}
