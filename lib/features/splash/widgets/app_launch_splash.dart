import 'package:flutter/material.dart';
import 'package:recall_app/core/constants/app_constants.dart';

class AppLaunchSplash extends StatefulWidget {
  final double opacity;

  const AppLaunchSplash({
    super.key,
    required this.opacity,
  });

  @override
  State<AppLaunchSplash> createState() => _AppLaunchSplashState();
}

class _AppLaunchSplashState extends State<AppLaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    final curved = CurveTween(curve: Curves.easeInOut).animate(_controller);
    _float = Tween<double>(begin: -3, end: 5).animate(curved);
    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.opacity,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: ColoredBox(
          color: const Color(0xFFF4FAF6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _float.value),
                      child: Transform.scale(
                        scale: _scale.value,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 164,
                    height: 164,
                    child: Image.asset(
                      'assets/branding/logo_clean.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Color(0xFF1E4A37),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
