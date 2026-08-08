import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';

/// Analytics data model.
class UsageStats {
  final int totalBytesIn;
  final int totalBytesOut;
  final int totalConnections;
  final int peakPeers;
  final Duration totalUptime;
  final List<double> hourlyTraffic; // Last 24h, MB per hour

  const UsageStats({
    this.totalBytesIn = 0,
    this.totalBytesOut = 0,
    this.totalConnections = 0,
    this.peakPeers = 0,
    this.totalUptime = Duration.zero,
    this.hourlyTraffic = const [],
  });
}

/// Provider for usage stats.
final usageStatsProvider = StateProvider<UsageStats>((ref) => const UsageStats());

/// Analytics / Usage Stats Screen.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final stats = ref.watch(usageStatsProvider);
    final isMaster = role == NodeRole.master;
    final bgColor = isMaster ? AirBridgeColors.masterPrimary : AirBridgeColors.clientSurface;
    final textColor = isMaster ? Colors.white : AirBridgeColors.clientText;
    final accentColor = isMaster ? AirBridgeColors.masterAccent : AirBridgeColors.clientPrimary;
    final cardColor = isMaster ? AirBridgeColors.masterSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Analytics', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Data In',
                value: _formatBytes(stats.totalBytesIn),
                icon: Icons.arrow_downward_rounded,
                color: accentColor,
                cardColor: cardColor,
                textColor: textColor,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Data Out',
                value: _formatBytes(stats.totalBytesOut),
                icon: Icons.arrow_upward_rounded,
                color: accentColor,
                cardColor: cardColor,
                textColor: textColor,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Connections',
                value: '${stats.totalConnections}',
                icon: Icons.link_rounded,
                color: accentColor,
                cardColor: cardColor,
                textColor: textColor,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Peak Peers',
                value: '${stats.peakPeers}',
                icon: Icons.people_rounded,
                color: accentColor,
                cardColor: cardColor,
                textColor: textColor,
              )),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(
            label: 'Total Uptime',
            value: _formatDuration(stats.totalUptime),
            icon: Icons.timer_rounded,
            color: accentColor,
            cardColor: cardColor,
            textColor: textColor,
          ),
          const SizedBox(height: 24),

          // Traffic chart
          Text(
            'HOURLY TRAFFIC (24H)',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: stats.hourlyTraffic.isEmpty
                ? Center(
                    child: Text(
                      'No traffic data yet',
                      style: TextStyle(color: textColor.withValues(alpha: 0.4)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: stats.hourlyTraffic.reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: List.generate(
                        stats.hourlyTraffic.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: stats.hourlyTraffic[i],
                              color: accentColor,
                              width: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
