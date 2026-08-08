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
  bool _ttlEnabled = true;
  bool _fragEnabled = true;
  bool _uaEnabled = true;

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
      final status = await client.getStatus();
      if (status.startedAtUnixMs > 0) {
        ref.read(sessionStartTimeProvider.notifier).state =
            DateTime.fromMillisecondsSinceEpoch(status.startedAtUnixMs);
      }
      if (mounted) {
        setState(() {
          _qrCredentials = creds;
          _peerCount = peers;
        });
        
        // Trigger QR entrance animation again to make regenerate button feel alive
        _entryController.forward(from: 0.5);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daemon status error: $e')),
        );
      }
    }
  }

  Future<void> _syncDaemonPrivacyConfig() async {
    try {
      final daemonClient = ref.read(daemonProvider);
      await daemonClient.setPrivacyConfig(
        ttlEnabled: _ttlEnabled,
        fragmenterEnabled: _fragEnabled,
        uaHarmonizeEnabled: _uaEnabled,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync privacy config: $e')),
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
                title: const Row(
                  children: [
                    _PulsingStatusDot(),
                    SizedBox(width: 10),
                    Text(
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
                    const SizedBox(height: 24),

                    // Dynamic Privacy Engine Toggles
                    _buildPrivacyToggles(),
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
    final daemonStart = ref.watch(sessionStartTimeProvider) ?? _sessionStart;
    final elapsed = DateTime.now().difference(daemonStart);
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
          // QR Code Entrance Transition (ANIMATION #2)
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _entryController,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(
              opacity: _entryController,
              child: Container(
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
          Row(
            children: [
              const Text(
                'Connected Devices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$_peerCount active',
                style: const TextStyle(
                  color: AirBridgeColors.masterAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _peerCount == 0
                ? Container(
                    key: const ValueKey(0),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      'No connected peers. Share QR code above to connect devices.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  )
                : Column(
                    key: ValueKey(_peerCount),
                    children: List.generate(_peerCount, (index) {
                      final name = 'Connected Peer #${index + 1}';
                      return Column(
                        children: [
                          if (index > 0) const Divider(color: Colors.white10, height: 24),
                          _DeviceRow(
                            name: name,
                            platform: 'Active Client',
                            icon: Icons.devices_rounded,
                            color: AirBridgeColors.masterAccent,
                            bytesUsed: 'Data secured',
                            latency: 'Real-time',
                          ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggles() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AirBridgeColors.masterSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AirBridgeColors.masterAccent, size: 20),
              SizedBox(width: 10),
              Text(
                'DYNAMIC PRIVACY ENGINE TOGGLES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PrivacySwitch(
            title: 'TTL Normalization',
            subtitle: 'Masks packet TTL to 64 (Mobile OS appearance)',
            value: _ttlEnabled,
            onChanged: (val) {
              setState(() => _ttlEnabled = val);
              _syncDaemonPrivacyConfig();
            },
          ),
          const Divider(color: Colors.white10, height: 20),
          _PrivacySwitch(
            title: 'Packet Fragmentation',
            subtitle: 'Splits TLS records to prevent DPI identification',
            value: _fragEnabled,
            onChanged: (val) {
              setState(() => _fragEnabled = val);
              _syncDaemonPrivacyConfig();
            },
          ),
          const Divider(color: Colors.white10, height: 20),
          _PrivacySwitch(
            title: 'User-Agent Harmonization',
            subtitle: 'Harmonizes HTTP headers to mobile Chrome',
            value: _uaEnabled,
            onChanged: (val) {
              setState(() => _uaEnabled = val);
              _syncDaemonPrivacyConfig();
            },
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

class _PulsingStatusDot extends StatefulWidget {
  const _PulsingStatusDot();

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.4);
        final opacity = 1.0 - (_controller.value * 0.5);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AirBridgeColors.masterAccent.withValues(alpha: opacity),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AirBridgeColors.masterAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AirBridgeColors.masterAccent,
        ),
      ],
    );
  }
}
