part of '../../../../exercise.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;

  const AudioPlayerWidget({super.key, this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool isPlaying = false;
  double progress = 0.0;
  String currentTime = '00:46';
  String remainingTime = '-00:34';

  void _togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              border: Border.all(color: const Color(0xFFE3E8EF), width: 1.8),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF0D121C), size: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFCDD5DF), borderRadius: BorderRadius.circular(20)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF554FF0), borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentTime,
                    style: const TextStyle(color: Color(0xFF7F8EA4), fontSize: 10, fontWeight: FontWeight.w500, height: 1.5),
                  ),
                  Text(
                    remainingTime,
                    style: const TextStyle(color: Color(0xFF7F8EA4), fontSize: 10, fontWeight: FontWeight.w500, height: 1.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
