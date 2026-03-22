import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onFinish;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _saving = false;

  static const _pages = [
    (
      title: 'Welcome to QuakeNav',
      body: 'This app guides you to the correct evacuation route during earthquakes.',
      icon: Icons.shield_outlined,
    ),
    (
      title: 'Live Earthquake Alerts',
      body: 'When intensity reaches evacuation level, you get alarm, vibration, and emergency UI.',
      icon: Icons.notifications_active_outlined,
    ),
    (
      title: 'Assigned Building Routing',
      body: 'Your route is based on your registered building so exits are coordinated.',
      icon: Icons.route_outlined,
    ),
    (
      title: 'Open Map Fast',
      body: 'Use the bubble and alert actions to open navigation immediately.',
      icon: Icons.map_outlined,
    ),
    (
      title: 'Quick Tutorial',
      body:
          '1) Allow location and notifications.\n'
          '2) Check your assigned building in Settings.\n'
          '3) During intensity 5+, follow the route card and ETA.\n'
          '4) Long-press your marker for emergency call.',
      icon: Icons.menu_book_outlined,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onFinish();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF7F7F7);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saving ? null : _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC4C02).withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 42, color: const Color(0xFFFC4C02)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF4D4D4D),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? const Color(0xFFFC4C02)
                          : const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () {
                          if (_index == _pages.length - 1) {
                            _finish();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFC4C02),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
