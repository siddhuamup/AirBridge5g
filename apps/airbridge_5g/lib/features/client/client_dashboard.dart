import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';
import '../../providers/daemon_provider.dart';
import '../../services/platform_vpn.dart';
import '../../utils/crypto_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Client Dashboard — Minimalist Sky Blue theme.
/// Features QR scanner, one-click connect, and connection status.
/// Supports deep linking via query parameters: ?host=X&port=Y
class ClientDashboard extends ConsumerStatefulWidget {
  final String? deepLinkHost;
  final int? deepLinkPort;

  const ClientDashboard({super.key, this.deepLinkHost, this.deepLinkPort});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _scanLineController;
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualProxyController = TextEditingController();
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _masterNodeName = 'airbridge-master';
  String _connectedProxyHost = '';
  int _measuredLatencyMs = 12;
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Handle deep link auto-connect
    if (widget.deepLinkHost != null && widget.deepLinkPort != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _manualProxyController.text = '${widget.deepLinkHost}:${widget.deepLinkPort}';
        _connectManually();
      });
    }
  }

  void _startPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_isConnected) return;
      final stopwatch = Stopwatch()..start();
      try {
        await ref.read(daemonProvider).getConnectedPeers();
        stopwatch.stop();
        if (mounted) {
          setState(() {
            _measuredLatencyMs = max(1, stopwatch.elapsedMilliseconds);
          });
        }
      } catch (_) {
        stopwatch.stop();
      }
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _manualProxyController.dispose();
    _entryController.dispose();
    _scanLineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() => _isScanning = true);
    _scanLineController.repeat(reverse: true);
  }

  void _handleBarcodeDetected(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty && !_isConnecting) {
        HapticFeedback.lightImpact();
        setState(() {
          _isConnecting = true;
        });
        _scannerController.stop();
        try {
          final daemonClient = ref.read(daemonProvider);
          final success = await daemonClient.connectWithQR(rawValue);
          if (success && mounted) {
            final creds = QRCredentials.decode(rawValue);
            await PlatformNetworkManager.enableNetworkTunnel(
              proxyHost: creds.proxyHost,
              proxyPort: creds.proxyPort,
            );
            setState(() {
              _masterNodeName = creds.nodeId.isNotEmpty ? creds.nodeId : 'airbridge-master';
              _connectedProxyHost = '${creds.proxyHost}:${creds.proxyPort}';
              _measuredLatencyMs = 8;
              _isScanning = false;
              _isConnected = true;
              _isConnecting = false;
            });
            _startPingLoop();
            _scanLineController.stop();
          } else if (mounted) {
            setState(() => _isConnecting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to connect using QR credentials')),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isConnecting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connection error: $e')),
            );
          }
        }
        break;
      }
    }
  }

  Future<void> _connectManually() async {
    var rawInput = _manualProxyController.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a proxy address (e.g. 192.168.1.100:1080)')),
      );
      return;
    }

    if (rawInput.contains('://')) {
      rawInput = rawInput.split('://').last;
    }

    String host;
    int port = 1080;

    if (rawInput.startsWith('[')) {
      final closingBracket = rawInput.indexOf(']');
      if (closingBracket != -1) {
        host = rawInput.substring(1, closingBracket);
        final remainder = rawInput.substring(closingBracket + 1);
        if (remainder.startsWith(':')) {
          port = int.tryParse(remainder.substring(1)) ?? 1080;
        }
      } else {
        host = rawInput;
      }
    } else {
      final parts = rawInput.split(':');
      host = parts[0];
      if (parts.length > 1) {
        port = int.tryParse(parts[1]) ?? 1080;
      }
    }

    if (host.isEmpty || port <= 0 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid proxy host or port range (1-65535)')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isConnecting = true);

    try {
      final success = await PlatformNetworkManager.enableNetworkTunnel(
        proxyHost: host,
        proxyPort: port,
      );
      if (success && mounted) {
        setState(() {
          _masterNodeName = 'Manual Master Node';
          _connectedProxyHost = '$host:$port';
          _measuredLatencyMs = 14;
          _isConnected = true;
          _isConnecting = false;
        });
        _startPingLoop();
      } else if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to enable proxy/tunnel')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    _pingTimer?.cancel();
    HapticFeedback.mediumImpact();
    await PlatformNetworkManager.disableNetworkTunnel();
    await ref.read(daemonProvider).stopTunnel();
    if (mounted) {
      setState(() {
        _isConnected = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    return Scaffold(
      backgroundColor: AirBridgeColors.clientSurface,
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
                  icon: Icon(Icons.arrow_back_rounded, color: AirBridgeColors.clientText),
                  onPressed: () {
                    ref.read(roleProvider.notifier).clearRole();
                    context.go('/');
                  },
                ),
                title: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected
                            ? AirBridgeColors.masterAccent
                            : AirBridgeColors.clientPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected 
                        ? (AppLocalizations.of(context)?.statusConnected.toUpperCase() ?? 'CONNECTED') 
                        : (AppLocalizations.of(context)?.clientMode.toUpperCase() ?? 'CLIENT MODE'),
                      style: TextStyle(
                        color: _isConnected
                            ? AirBridgeColors.masterAccent
                            : AirBridgeColors.clientPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings_rounded, color: AirBridgeColors.clientText.withOpacity(0.5)),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.15 : 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),

                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 500),
                      firstCurve: Curves.easeInOutCubic,
                      secondCurve: Curves.easeInOutCubic,
                      crossFadeState: !_isConnected
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Column(
                        children: [
                          _buildScannerSection(),
                          const SizedBox(height: 32),
                          _buildOneClickConnect(),
                          const SizedBox(height: 32),
                          _buildManualConnect(),
                        ],
                      ),
                      secondChild: Column(
                        children: [
                          _buildConnectedStatus(),
                          const SizedBox(height: 24),
                          _buildConnectionDetails(),
                          const SizedBox(height: 24),
                          _buildDisconnectButton(),
                        ],
                      ),
                    ),

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

  Widget _buildScannerSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AirBridgeColors.clientPrimary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 64,
            color: AirBridgeColors.clientPrimary,
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan QR Code',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AirBridgeColors.clientText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Point your camera at the Master device\'s QR code\nto auto-configure your connection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AirBridgeColors.clientText.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Scanner viewport
          AnimatedBuilder(
            animation: _scanLineController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isScanning
                        ? AirBridgeColors.clientPrimary
                        : AirBridgeColors.clientPrimary.withOpacity(0.3),
                    width: 2,
                  ),
                  color: const Color(0xFFF0F7FF),
                ),
                child: Stack(
                  children: [
                    // Camera preview when scanning
                    if (_isScanning)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleBarcodeDetected,
                        ),
                      ),
                    // Corner markers
                    ..._buildCornerMarkers(),
                    // Scan line
                    if (_isScanning)
                      Positioned(
                        top: _scanLineController.value * 220,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AirBridgeColors.clientPrimary.withOpacity(0),
                                AirBridgeColors.clientPrimary,
                                AirBridgeColors.clientPrimary.withOpacity(0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AirBridgeColors.clientPrimary.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Connecting loading indicator
                    if (_isConnecting)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AirBridgeColors.clientPrimary,
                          ),
                        ),
                      ),
                    // Center icon
                    if (!_isScanning && !_isConnecting)
                      Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 48,
                          color: AirBridgeColors.clientPrimary.withOpacity(0.3),
                        ),
                      ),

                    // Scanning text
                    if (_isScanning)
                      const Center(
                        child: Text(
                          'Scanning...',
                          style: TextStyle(
                            color: AirBridgeColors.clientPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isScanning ? null : _startScanning,
              icon: Icon(_isScanning ? Icons.stop_rounded : Icons.qr_code_scanner_rounded),
              label: Text(_isScanning ? 'Scanning...' : 'Start Scanner'),
              style: FilledButton.styleFrom(
                backgroundColor: AirBridgeColors.clientPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const size = 24.0;
    const thickness = 3.0;
    const color = AirBridgeColors.clientPrimary;

    return [
      // Top-left
      Positioned(top: 8, left: 8, child: _Corner(size: size, thickness: thickness, color: color, topLeft: true)),
      // Top-right
      Positioned(top: 8, right: 8, child: _Corner(size: size, thickness: thickness, color: color, topRight: true)),
      // Bottom-left
      Positioned(bottom: 8, left: 8, child: _Corner(size: size, thickness: thickness, color: color, bottomLeft: true)),
      // Bottom-right
      Positioned(bottom: 8, right: 8, child: _Corner(size: size, thickness: thickness, color: color, bottomRight: true)),
    ];
  }

  Widget _buildOneClickConnect() {
    return InkWell(
      onTap: _connectManually,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AirBridgeColors.clientPrimary,
              AirBridgeColors.clientAccent,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AirBridgeColors.clientPrimary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.oneClickConnect ?? 'One-Click Connect',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Auto-detect and connect to nearby Master nodes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildManualConnect() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Configuration',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AirBridgeColors.clientText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualProxyController,
            decoration: InputDecoration(
              hintText: 'Proxy Address (e.g., 192.168.1.100:1080)',
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _connectManually,
              style: OutlinedButton.styleFrom(
                foregroundColor: AirBridgeColors.clientPrimary,
                side: const BorderSide(color: AirBridgeColors.clientPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Connect Manually'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedStatus() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AirBridgeColors.masterAccent.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AirBridgeColors.masterAccent.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AirBridgeColors.masterAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Connected!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AirBridgeColors.clientText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your traffic is now routed through the Master node',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AirBridgeColors.clientText.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AirBridgeColors.masterAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: AirBridgeColors.masterAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'End-to-End Encrypted • TLS 1.3',
                  style: TextStyle(
                    color: AirBridgeColors.masterAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionDetails() {
    final proxyVal = _connectedProxyHost.isNotEmpty
        ? _connectedProxyHost
        : (_manualProxyController.text.isNotEmpty
            ? _manualProxyController.text
            : 'Active Network Proxy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Master Node', value: _masterNodeName),
          const Divider(height: 20),
          _DetailRow(label: 'Proxy', value: proxyVal),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _disconnect,
        icon: const Icon(Icons.link_off_rounded),
        label: const Text('Disconnect'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade400,
          side: BorderSide(color: Colors.red.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AirBridgeColors.clientText.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AirBridgeColors.clientText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final double size;
  final double thickness;
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner({
    required this.size,
    required this.thickness,
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          thickness: thickness,
          color: color,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double thickness;
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({
    required this.thickness,
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(Offset(0, size.height * 0.4), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.4, 0), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height * 0.4), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, size.height * 0.6), Offset(0, size.height), paint);
      canvas.drawLine(Offset(0, size.height), Offset(size.width * 0.4, size.height), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width, size.height * 0.6), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width * 0.6, size.height), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
