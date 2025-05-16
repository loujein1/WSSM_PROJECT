import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/water_usage.dart';

class BarChartWidget extends StatelessWidget {
  final List<WaterUsage> waterUsage;

  const BarChartWidget({super.key, required this.waterUsage});

  @override
  Widget build(BuildContext context) {
    // Group data by location
    Map<String, double> locationUsage = {};
    for (var entry in waterUsage) {
      locationUsage.update(entry.location, (value) => value + entry.amountUsed, ifAbsent: () => entry.amountUsed);
    }

    List<BarChartGroupData> barGroups = [];
    int index = 0;
    locationUsage.forEach((location, usage) {
      barGroups.add(
        BarChartGroupData(
          x: index++,
          barRods: [
            BarChartRodData(
              toY: usage,
              color: Colors.blueAccent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Water Usage by Location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(locationUsage.keys.toList()[value.toInt()], style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
