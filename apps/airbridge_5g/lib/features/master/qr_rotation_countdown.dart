import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daemon_provider.dart';
import '../../app.dart';

/// Auto QR rotation provider — tracks when QR credentials expire and
/// automatically regenerates them every 24 hours.
final qrExpiresAtProvider = StateProvider<DateTime?>((ref) => null);

/// Widget that displays a 24h countdown timer and auto-rotates QR credentials.
class QrRotationCountdown extends ConsumerStatefulWidget {
  final VoidCallback onRotate;

  const QrRotationCountdown({super.key, required this.onRotate});

  @override
  ConsumerState<QrRotationCountdown> createState() => _QrRotationCountdownState();
}

class _QrRotationCountdownState extends ConsumerState<QrRotationCountdown> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final expiresAt = ref.read(qrExpiresAtProvider);
    if (expiresAt == null) {
      // Set initial expiry to 24h from now
      final newExpiry = DateTime.now().add(const Duration(hours: 24));
      ref.read(qrExpiresAtProvider.notifier).state = newExpiry;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expiresAt = ref.read(qrExpiresAtProvider);
      if (expiresAt == null) return;

      final now = DateTime.now();
      final remaining = expiresAt.difference(now);

      if (remaining.isNegative) {
        // QR expired — rotate!
        _rotateQr();
      } else {
        if (mounted) {
          setState(() {
            _remaining = remaining;
          });
        }
      }
    });
  }

  Future<void> _rotateQr() async {
    // Set new expiry
    final newExpiry = DateTime.now().add(const Duration(hours: 24));
    ref.read(qrExpiresAtProvider.notifier).state = newExpiry;

    // Trigger regeneration callback
    widget.onRotate();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    final timeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final progress = _remaining.inSeconds > 0
        ? _remaining.inSeconds / const Duration(hours: 24).inSeconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AirBridgeColors.masterSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AirBridgeColors.masterAccent.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: _remaining.inMinutes < 30
                  ? AirBridgeColors.masterError
                  : AirBridgeColors.masterAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Valid For',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  color: _remaining.inMinutes < 30
                      ? AirBridgeColors.masterError
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _rotateQr,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AirBridgeColors.masterAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AirBridgeColors.masterAccent,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
