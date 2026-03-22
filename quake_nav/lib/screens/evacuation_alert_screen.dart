import 'package:flutter/material.dart';

class EvacuationAlertScreen extends StatefulWidget {
  final VoidCallback onOpenMap;
  final String intensityText;
  final Color accentColor;

  const EvacuationAlertScreen({
    super.key,
    required this.onOpenMap,
    this.intensityText = 'Earthquake detected',
    this.accentColor = const Color(0xFFC62828),
  });

  @override
  State<EvacuationAlertScreen> createState() => _EvacuationAlertScreenState();
}

class _EvacuationAlertScreenState extends State<EvacuationAlertScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragUpDistance = 0;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMap() {
    if (_opening) return;
    _opening = true;
    widget.onOpenMap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F6F9);
    final panel = isDark ? const Color(0xFF151A21) : Colors.white;
    final muted = isDark ? Colors.white70 : const Color(0xFF5D6672);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {
            _dragUpDistance = 0;
          },
          onVerticalDragUpdate: (details) {
            _dragUpDistance += details.delta.dy;
            if (_dragUpDistance <= -48) {
              _openMap();
            }
          },
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -200) {
              _openMap();
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/quakenav_logo_inapp.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'QuakeNav',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.intensityText,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.warning_amber_rounded, color: widget.accentColor, size: 88),
              const SizedBox(height: 18),
              Text(
                'EARTHQUAKE ALERT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1D2530),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Swipe up to open evacuation route',
                style: TextStyle(
                  color: muted,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 44),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final arrowColor =
                      isDark ? Colors.white : widget.accentColor;
                  final pulse = 0.92 + (0.18 * (1 - (2 * (t - 0.5).abs())));

                  Widget chevron(double delay) {
                    final phase = (t + delay) % 1.0;
                    final y = 42.0 - (phase * 42.0);
                    final opacity = (1.0 - phase).clamp(0.0, 1.0);
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: y,
                      child: Opacity(
                        opacity: opacity,
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: arrowColor,
                          size: 44,
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    width: 116,
                    height: 108,
                    child: Stack(
                      children: [
                        Align(
                          alignment: const Alignment(0, -0.10),
                          child: Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: arrowColor.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        chevron(0.00),
                        chevron(0.22),
                        chevron(0.44),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Swipe up to start',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: FilledButton(
                  onPressed: _openMap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Open Evacuation Map'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
