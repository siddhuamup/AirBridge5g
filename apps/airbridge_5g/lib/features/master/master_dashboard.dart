import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/daemon_provider.dart';
import '../../utils/crypto_utils.dart';

/// Master Dashboard — Dark Navy + Radiant Green theme.
/// Shows QR code generator, real-time traffic graph, connected devices, and session timer.
class MasterDashboard extends ConsumerStatefulWidget {
  const MasterDashboard({super.key});

  @override
  ConsumerState<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends ConsumerState<MasterDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  StreamSubscription? _trafficSub;
  QRCredentials? _qrCredentials;
  DateTime _sessionStart = DateTime.now();
  int _peerCount = 0;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // Subscribe to real daemon traffic stream
    final client = ref.read(daemonProvider);
    _trafficSub = client.streamTrafficStats().listen((data) {
      if (mounted) {
        ref.read(trafficDataProvider.notifier).addDataPoint(
          (data['throughput_out_bps'] as num?)?.toDouble() ?? 0.0,  // download
          (data['throughput_in_bps'] as num?)?.toDouble() ?? 0.0,   // upload
        );
      }
    });
    
    // Fetch daemon status and credentials
    _fetchDaemonStatus();
  }

  Future<void> _fetchDaemonStatus() async {
    final client = ref.read(daemonProvider);
    try {
      final creds = await client.generateQRCredentials();
      final peers = await client.getConnectedPeers();
      if (mounted) {
        setState(() {
          _qrCredentials = creds;
          _peerCount = peers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daemon status error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _trafficSub?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trafficData = ref.watch(trafficDataProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: AirBridgeColors.masterPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _entryController,
            curve: Curves.easeOut,
          ),
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(roleProvider.notifier).clearRole();
                    ref.read(trafficDataProvider.notifier).reset();
                    context.go('/');
                  },
                ),
                title: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AirBridgeColors.masterAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MASTER NODE',
                      style: TextStyle(
                        color: AirBridgeColors.masterAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white54),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.05 : 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),

                    // Stats Row
                    _buildStatsRow(trafficData),
                    const SizedBox(height: 24),

                    // Main content — QR + Graph
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildQRSection()),
                          const SizedBox(width: 24),
                          Expanded(flex: 3, child: _buildTrafficGraph(trafficData)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildQRSection(),
                          const SizedBox(height: 24),
                          _buildTrafficGraph(trafficData),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Connected Devices
                    _buildConnectedDevices(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(TrafficData data) {
    final elapsed = DateTime.now().difference(_sessionStart);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'UPLOAD',
          value: data.formattedUpload,
          icon: Icons.arrow_upward_rounded,
          color: AirBridgeColors.masterAccent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'DOWNLOAD',
          value: data.formattedDownload,
          icon: Icons.arrow_downward_rounded,
          color: const Color(0xFF40C4FF),
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'PEERS',
          value: '$_peerCount',
          icon: Icons.devices_rounded,
          color: const Color(0xFFFFAB40),
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'SESSION',
          value: '${minutes}m ${seconds}s',
          icon: Icons.timer_rounded,
          color: const Color(0xFFE040FB),
        )),
      ],
    );
  }

  Widget _buildQRSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AirBridgeColors.masterSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AirBridgeColors.masterAccent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Scan to Connect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this QR code with clients',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AirBridgeColors.masterAccent.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: QrImageView(
              data: _qrCredentials?.encode() ?? '{}',
              version: QrVersions.auto,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.roundedRect,
                color: Color(0xFF0A1628),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.roundedRect,
                color: Color(0xFF0A1628),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Refresh button
          TextButton.icon(
            onPressed: _fetchDaemonStatus,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Regenerate'),
            style: TextButton.styleFrom(
              foregroundColor: AirBridgeColors.masterAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficGraph(TrafficData data) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AirBridgeColors.masterSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AirBridgeColors.masterAccent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live Traffic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _LegendDot(color: AirBridgeColors.masterAccent, label: 'Upload'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFF40C4FF), label: 'Download'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: data.uploadHistory.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for traffic...',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25e6,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1e6).toStringAsFixed(0)}M',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 120e6,
                      lineBarsData: [
                        // Upload line
                        LineChartBarData(
                          spots: data.uploadHistory
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AirBridgeColors.masterAccent,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AirBridgeColors.masterAccent.withValues(alpha: 0.1),
                          ),
                        ),
                        // Download line
                        LineChartBarData(
                          spots: data.downloadHistory
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: const Color(0xFF40C4FF),
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF40C4FF).withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AirBridgeColors.masterSurface,
                        ),
                      ),
                    ),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDevices() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AirBridgeColors.masterSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AirBridgeColors.masterAccent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Connected Devices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '3 active',
                style: TextStyle(
                  color: AirBridgeColors.masterAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DeviceRow(
            name: 'Windows Laptop',
            platform: 'Windows 11',
            icon: Icons.laptop_windows_rounded,
            color: const Color(0xFF40C4FF),
            bytesUsed: '2.4 GB',
            latency: '12ms',
          ),
          const Divider(color: Colors.white10, height: 24),
          _DeviceRow(
            name: 'MacBook Pro',
            platform: 'macOS Sonoma',
            icon: Icons.laptop_mac_rounded,
            color: const Color(0xFFE040FB),
            bytesUsed: '1.8 GB',
            latency: '8ms',
          ),
          const Divider(color: Colors.white10, height: 24),
          _DeviceRow(
            name: 'Android Tablet',
            platform: 'Android 14',
            icon: Icons.tablet_android_rounded,
            color: AirBridgeColors.masterAccent,
            bytesUsed: '890 MB',
            latency: '5ms',
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AirBridgeColors.masterSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final String name;
  final String platform;
  final IconData icon;
  final Color color;
  final String bytesUsed;
  final String latency;

  const _DeviceRow({
    required this.name,
    required this.platform,
    required this.icon,
    required this.color,
    required this.bytesUsed,
    required this.latency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                platform,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              bytesUsed,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              latency,
              style: TextStyle(
                color: AirBridgeColors.masterAccent.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
