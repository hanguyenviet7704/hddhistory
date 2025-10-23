part of '../../../../../exercise.dart';

class CuesStatusBar extends StatelessWidget {
  const CuesStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '9:41',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A202C)),
          ),
          Container(
            width: 125,
            height: 37,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(100)),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Icon(Icons.wifi, size: 17, color: Colors.black),
              const SizedBox(width: 8),
              Icon(Icons.battery_full, size: 24, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }
}
