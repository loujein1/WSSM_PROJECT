import 'package:flutter/material.dart';

class AlertWidget extends StatelessWidget {
  final double waterLevel;

  const AlertWidget({super.key, required this.waterLevel});

  @override
  Widget build(BuildContext context) {
    String message = "";
    Color color = Colors.green;

    if (waterLevel < 20) {
      message = "⚠️ Critically Low Water Level!";
      color = Colors.red;
    } else if (waterLevel > 90) {
      message = "⚠️ Overflow Risk!";
      color = Colors.orange;
    }

    return message.isNotEmpty
        ? Card(
            color: color.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          )
        : const SizedBox();
  }
}
