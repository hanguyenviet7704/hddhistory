part of '../../onboard.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  final List<OnboardContent> _onboardContents = [
    OnboardContent(
      chatMessage: "Don't let poor communication hold you back anymore.",
      title: "Missed chances",
      subtitle: "Unspoken ideas",
      description: "Limited growth",
      iconPath: "assets/svg/common/onboard_icon_1.svg",
    ),
    OnboardContent(
      chatMessage: "MeUp offers a structured approach to mastering your voice...",
      title: "No one is born a great communicator.",
      subtitle: "It's a skill you can build.",
      description: "",
      iconPath: "assets/svg/common/onboard_icon_2.svg",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCCF1EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipButton(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: _onboardContents.length,
                itemBuilder: (context, index) {
                  return _buildOnboardContent(_onboardContents[index]);
                },
              ),
            ),
            _buildPageIndicator(),
            SizedBox(height: 34.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              // Handle skip action
            },
            child: AppText(
              'Skip',
              style: AppStyle.text16.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF364152),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardContent(OnboardContent content) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildBackgroundIllustration(),
                _buildCharacterSection(content),
              ],
            ),
          ),
          _buildContentCard(content),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildBackgroundIllustration() {
    return Positioned(
      left: -29.w,
      top: -24.h,
      child: SizedBox(
        width: 421.162.w,
        height: 400.h,
        child: Stack(
          children: [
            // Background layers would go here
            // For now, we'll use a placeholder
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFCCF1EE).withValues(alpha: 0),
                    const Color(0xFFCCF1EE),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSection(OnboardContent content) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChatBubble(content.chatMessage),
          SizedBox(height: 32.h),
          _buildCharacterIllustration(content.iconPath),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String message) {
    return SizedBox(
      width: 280.w,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C6AA).withValues(alpha: 0.12),
                  offset: const Offset(0, 4),
                  blurRadius: 24,
                ),
              ],
            ),
            child: AppText(
              message,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w400,
                color: const Color(0xFF364152),
                height: 1.75,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 10.h),
          _buildChatArrow(),
        ],
      ),
    );
  }

  Widget _buildChatArrow() {
    return SizedBox(
      width: 280.w,
      height: 10.h,
      child: Center(
        child: Transform.rotate(
          angle: 3.14159, // 180 degrees
          child: SizedBox(
            width: 25.865.w,
            height: 16.h,
            child: CustomPaint(
              painter: ChatArrowPainter(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterIllustration(String iconPath) {
    return SizedBox(
      width: 210.45.w,
      height: 160.h,
      child: Center(
        child: SizedBox(
          width: 205.29.w,
          height: 201.802.h,
          child: Image.asset(
            iconPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(OnboardContent content) {
    return Container(
      width: 335.w,
      height: 260.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF5B616D).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildContentHeader(content),
            const Spacer(),
            _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentHeader(OnboardContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentIcon(),
        SizedBox(height: 8.h),
        _buildContentText(content),
      ],
    );
  }

  Widget _buildContentIcon() {
    return SizedBox(
      width: 24.w,
      height: 24.h,
      child: Image.asset(
        "assets/svg/common/onboard_vector.svg",
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildContentText(OnboardContent content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.title.isNotEmpty)
          AppText(
            content.title,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0D121C),
              height: 1.5,
            ),
          ),
        if (content.subtitle.isNotEmpty) ...[
          SizedBox(height: 12.h),
          AppText(
            content.subtitle,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF554FF0),
              height: 1.5,
            ),
          ),
        ],
        if (content.description.isNotEmpty) ...[
          SizedBox(height: 12.h),
          AppText(
            content.description,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0D121C),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _onboardContents.length,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: index == currentPage ? const Color(0xFF462BF4) : const Color(0xFFC1C5CD),
              borderRadius: BorderRadius.circular(50.r),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardContent {
  final String chatMessage;
  final String title;
  final String subtitle;
  final String description;
  final String iconPath;

  OnboardContent({
    required this.chatMessage,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconPath,
  });
}

class ChatArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
