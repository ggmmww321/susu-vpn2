import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/vpn_provider.dart';
import '../../../core/providers/server_provider.dart';
import '../../../core/theme/app_theme.dart';

class ConnectButton extends StatefulWidget {
  const ConnectButton({super.key});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VpnProvider, ServerProvider>(
      builder: (context, vpn, server, _) {
        // 连接中时旋转
        if (vpn.isConnecting) {
          _rotateController.repeat();
        } else {
          _rotateController.stop();
          _rotateController.reset();
        }

        Color glowColor = _getGlowColor(vpn.status);
        Color buttonColor = _getButtonColor(vpn.status);
        IconData icon = _getIcon(vpn.status);

        return GestureDetector(
          onTap: () => _handleTap(context, vpn, server),
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rotateController]),
            builder: (context, child) {
              return Transform.scale(
                scale: vpn.isConnected ? _pulseAnimation.value : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈光晕
                    if (vpn.isConnected)
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              glowColor.withOpacity(0.3),
                              glowColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    // 旋转环（连接中）
                    if (vpn.isConnecting)
                      Transform.rotate(
                        angle: _rotateController.value * 2 * math.pi,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _ArcPainter(AppColors.primary),
                          ),
                        ),
                      ),
                    // 主按钮
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [buttonColor, buttonColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, VpnProvider vpn, ServerProvider server) {
    if (vpn.isConnecting || vpn.status == VpnStatus.disconnecting) return;

    if (vpn.isConnected) {
      vpn.disconnect();
    } else {
      final node = server.selectedNode;
      if (node == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先选择一个服务器'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      vpn.connect(node);
    }
  }

  Color _getGlowColor(VpnStatus status) {
    switch (status) {
      case VpnStatus.connected:
        return AppColors.connected;
      case VpnStatus.connecting:
        return AppColors.connecting;
      case VpnStatus.error:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getButtonColor(VpnStatus status) {
    switch (status) {
      case VpnStatus.connected:
        return AppColors.connected;
      case VpnStatus.connecting:
        return AppColors.connecting;
      case VpnStatus.error:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getIcon(VpnStatus status) {
    switch (status) {
      case VpnStatus.connected:
        return Icons.power_settings_new_rounded;
      case VpnStatus.connecting:
        return Icons.sync_rounded;
      case VpnStatus.disconnecting:
        return Icons.sync_rounded;
      case VpnStatus.error:
        return Icons.error_outline_rounded;
      default:
        return Icons.power_settings_new_rounded;
    }
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      math.pi * 1.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
