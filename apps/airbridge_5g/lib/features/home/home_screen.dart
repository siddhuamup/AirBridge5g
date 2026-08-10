import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../providers/role_provider.dart';

/// Home screen with role selection: "Provide Data" (Master) or "Receive Data" (Client).
/// This is the entry point of the polymorphic UI — selecting a role
/// triggers the entire app theme morph.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    return Scaffold(
      backgroundColor: AirBridgeColors.neutralSurface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.1 : 24,
                vertical: 24,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo & Title
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSubtitle(),
                  const SizedBox(height: 32),
                // Role Selection Cards
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: _buildMasterCard(context)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildClientCard(context)),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildMasterCard(context),
                      const SizedBox(height: 20),
                      _buildClientCard(context),
                    ],
                  ),
                const SizedBox(height: 32),
                // Version info
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glowOpacity = 0.3 + (_pulseController.value * 0.4);
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AirBridgeColors.masterAccent.withOpacity(glowOpacity),
                    AirBridgeColors.masterAccent.withOpacity(0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AirBridgeColors.masterPrimary,
                    border: Border.all(
                      color: AirBridgeColors.masterAccent.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    color: AirBridgeColors.masterAccent,
                    size: 28,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'AirBridge 5G',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Cross-Platform Network Resilience',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.6),
        letterSpacing: 1.5,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildMasterCard(BuildContext context) {
    return _RoleCard(
      title: 'Provide Data',
      subtitle: 'Share your 5G connection',
      description: 'Act as a Master node — generate QR credentials and share your cellular internet with connected peers.',
      icon: Icons.cloud_upload_rounded,
      gradientColors: [
        AirBridgeColors.masterPrimary,
        const Color(0xFF122244),
      ],
      accentColor: AirBridgeColors.masterAccent,
      glowColor: AirBridgeColors.masterAccentGlow,
      onTap: () {
        ref.read(roleProvider.notifier).setRole(NodeRole.master);
        context.go('/master');
      },
    );
  }

  Widget _buildClientCard(BuildContext context) {
    return _RoleCard(
      title: 'Receive Data',
      subtitle: 'Connect to a provider',
      description: 'Act as a Client — scan a QR code to auto-connect to a Master node\'s shared connection.',
      icon: Icons.cloud_download_rounded,
      gradientColors: [
        const Color(0xFF0277BD),
        AirBridgeColors.clientPrimary,
      ],
      accentColor: AirBridgeColors.clientAccent,
      glowColor: AirBridgeColors.clientSecondary,
      onTap: () {
        ref.read(roleProvider.notifier).setRole(NodeRole.client);
        context.go('/client');
      },
    );
  }

  Widget _buildFooter() {
    return Text(
      'v1.0.0 · Enterprise Network Resilience',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }
}

/// Animated role selection card with gradient background and glow effects.
class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color glowColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          final scale = 1.0 + (_hoverController.value * 0.02);
          final glowSpread = _hoverController.value * 20;

          return Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: widget.accentColor.withOpacity(0.2),
                highlightColor: widget.accentColor.withOpacity(0.1),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradientColors,
                  ),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(_isHovered ? 0.6 : 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withOpacity((0.15 + glowSpread * 0.005).clamp(0.0, 1.0)),
                      blurRadius: 20 + glowSpread,
                      spreadRadius: glowSpread / 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accentColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accentColor,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: widget.accentColor.withOpacity(0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
    );
  }
}
