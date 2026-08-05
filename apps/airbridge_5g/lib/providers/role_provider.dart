import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// The role of the current device in the AirBridge mesh.
enum NodeRole {
  unspecified,
  master,  // Provider: shares internet connection
  client,  // Receiver: consumes shared connection
}

/// Provides the current node role across the app.
/// Changing this triggers the polymorphic UI morph.
final roleProvider = StateNotifierProvider<RoleNotifier, NodeRole>((ref) {
  return RoleNotifier();
});

class RoleNotifier extends StateNotifier<NodeRole> {
  RoleNotifier() : super(NodeRole.unspecified);

  void setRole(NodeRole role) {
    state = role;
  }

  void clearRole() {
    state = NodeRole.unspecified;
  }

  bool get isMaster => state == NodeRole.master;
  bool get isClient => state == NodeRole.client;
  bool get hasRole => state != NodeRole.unspecified;
}

/// Connection state for the tunnel.
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Provides the connection state.
final connectionStateProvider = StateProvider<ConnectionState>((ref) {
  return ConnectionState.disconnected;
});

/// Provides the connected peer count.
final connectedPeerCountProvider = StateProvider<int>((ref) => 0);

/// Provides the session start time.
final sessionStartTimeProvider = StateProvider<DateTime?>((ref) => null);
