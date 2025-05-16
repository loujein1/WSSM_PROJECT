import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import '../../models/water_usage.dart';

class PieChartWidget extends StatelessWidget {
  final List<WaterUsage> waterUsage;

  const PieChartWidget({super.key, required this.waterUsage});

  @override
  Widget build(BuildContext context) {
    // Count occurrences of each status
    Map<String, double> statusCounts = {
      'Normal': 0,
      'Warning': 0,
      'Critical': 0,
    };

    for (var entry in waterUsage) {
      statusCounts[entry.status[0].toUpperCase() + entry.status.substring(1)] = (statusCounts[entry.status] ?? 0) + 1;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Water Usage Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PieChart(
                dataMap: statusCounts,
                colorList: const [Colors.green, Colors.yellow, Colors.red],
                chartValuesOptions: const ChartValuesOptions(showChartValuesInPercentage: true),
                legendOptions: const LegendOptions(showLegends: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
