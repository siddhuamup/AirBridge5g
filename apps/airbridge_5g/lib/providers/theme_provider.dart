import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current theme mode.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Provides real-time traffic data for the live graph.
final trafficDataProvider = StateNotifierProvider<TrafficDataNotifier, TrafficData>((ref) {
  return TrafficDataNotifier();
});

class TrafficData {
  final List<double> uploadHistory;   // bps values, last 60 data points
  final List<double> downloadHistory; // bps values, last 60 data points
  final double currentUpload;
  final double currentDownload;
  final int totalBytesIn;
  final int totalBytesOut;

  const TrafficData({
    this.uploadHistory = const [],
    this.downloadHistory = const [],
    this.currentUpload = 0,
    this.currentDownload = 0,
    this.totalBytesIn = 0,
    this.totalBytesOut = 0,
  });

  TrafficData copyWith({
    List<double>? uploadHistory,
    List<double>? downloadHistory,
    double? currentUpload,
    double? currentDownload,
    int? totalBytesIn,
    int? totalBytesOut,
  }) {
    return TrafficData(
      uploadHistory: uploadHistory ?? this.uploadHistory,
      downloadHistory: downloadHistory ?? this.downloadHistory,
      currentUpload: currentUpload ?? this.currentUpload,
      currentDownload: currentDownload ?? this.currentDownload,
      totalBytesIn: totalBytesIn ?? this.totalBytesIn,
      totalBytesOut: totalBytesOut ?? this.totalBytesOut,
    );
  }

  String get formattedUpload => _formatBps(currentUpload);
  String get formattedDownload => _formatBps(currentDownload);
  String get formattedTotalIn => _formatBytes(totalBytesIn);
  String get formattedTotalOut => _formatBytes(totalBytesOut);

  static String _formatBps(double bps) {
    if (bps >= 1e9) return '${(bps / 1e9).toStringAsFixed(1)} Gbps';
    if (bps >= 1e6) return '${(bps / 1e6).toStringAsFixed(1)} Mbps';
    if (bps >= 1e3) return '${(bps / 1e3).toStringAsFixed(1)} Kbps';
    return '${bps.toStringAsFixed(0)} bps';
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1e9) return '${(bytes / 1e9).toStringAsFixed(2)} GB';
    if (bytes >= 1e6) return '${(bytes / 1e6).toStringAsFixed(2)} MB';
    if (bytes >= 1e3) return '${(bytes / 1e3).toStringAsFixed(2)} KB';
    return '$bytes B';
  }
}

class TrafficDataNotifier extends StateNotifier<TrafficData> {
  DateTime? _lastTickTime;

  TrafficDataNotifier() : super(const TrafficData());

  void addDataPoint(double upload, double download) {
    final now = DateTime.now();
    final double elapsedSeconds = _lastTickTime != null
        ? now.difference(_lastTickTime!).inMilliseconds / 1000.0
        : 0.5;
    _lastTickTime = now;

    final newUpload = [...state.uploadHistory, upload];
    final newDownload = [...state.downloadHistory, download];

    // Keep last 60 data points
    if (newUpload.length > 60) newUpload.removeRange(0, newUpload.length - 60);
    if (newDownload.length > 60) newDownload.removeRange(0, newDownload.length - 60);

    state = state.copyWith(
      uploadHistory: newUpload,
      downloadHistory: newDownload,
      currentUpload: upload,
      currentDownload: download,
      totalBytesIn: state.totalBytesIn + (download / 8 * elapsedSeconds).round(),
      totalBytesOut: state.totalBytesOut + (upload / 8 * elapsedSeconds).round(),
    );
  }

  void reset() {
    _lastTickTime = null;
    state = const TrafficData();
  }
}
