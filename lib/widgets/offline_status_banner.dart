import 'package:flutter/material.dart';

class OfflineStatusBanner extends StatelessWidget {
  final bool isOffline;
  const OfflineStatusBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode: your last saved lessons, timetable, attendance, and tasks are available.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
