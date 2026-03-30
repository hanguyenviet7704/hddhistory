part of '../../output_practice.dart';

class OutputPracticePageShell extends StatelessWidget {
  const OutputPracticePageShell({
    super.key,
    required this.header,
    required this.child,
    required this.composer,
  });

  final Widget header;
  final Widget child;
  final Widget composer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC7C5FA),
              Color(0xFFF7EAE9),
              Color(0xFFF4E6DD),
            ],
            stops: [0, 0.85, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Unfocused(
            child: Column(
              children: [
                header,
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.08),
                        child: child,
                      ),
                    ),
                  ),
                ),
                composer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
