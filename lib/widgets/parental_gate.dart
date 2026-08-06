import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'common.dart';

/// Amazon and COPPA friendly parental gate.
///
/// A toddler cannot pass it: the parent must read a written instruction and
/// hold a specific number. No arithmetic that a lucky tap can solve.
class ParentalGate {
  static Future<bool> show(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => const _GateDialog(),
    );
    return ok ?? false;
  }
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  late final int _target = 2 + math.Random().nextInt(4); // 2..5
  late final List<int> _options = _buildOptions();
  int? _holding;
  double _progress = 0;
  bool _failed = false;

  List<int> _buildOptions() {
    final Set<int> set = <int>{_target};
    final math.Random rnd = math.Random();
    while (set.length < 4) {
      set.add(1 + rnd.nextInt(8));
    }
    final List<int> list = set.toList()..shuffle();
    return list;
  }

  Future<void> _hold(int value) async {
    setState(() {
      _holding = value;
      _failed = false;
      _progress = 0;
    });
    const int steps = 30;
    for (int i = 0; i < steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted || _holding != value) return;
      setState(() => _progress = (i + 1) / steps);
    }
    if (!mounted) return;
    if (value == _target) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _failed = true;
        _holding = null;
        _progress = 0;
      });
    }
  }

  void _release() {
    if (_holding != null) {
      setState(() {
        _holding = null;
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlossCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.lock_person_rounded,
                    size: 56, color: AppTheme.brand),
                const SizedBox(height: 12),
                const Text(
                  'Grown-ups only',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Press and hold the number $_target for two seconds.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _options.map(_numberButton).toList(),
                ),
                const SizedBox(height: 18),
                if (_failed)
                  const Text(
                    'That was not the right number. Please try again.',
                    style: TextStyle(color: Color(0xFFD32F2F), fontSize: 16),
                  ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberButton(int value) {
    final bool active = _holding == value;
    return GestureDetector(
      onTapDown: (_) => _hold(value),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: active ? AppTheme.brand : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brand, width: 3),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: active ? Colors.white : AppTheme.ink,
                  ),
                ),
              ),
            ),
            if (active)
              CircularProgressIndicator(
                value: _progress,
                strokeWidth: 6,
                color: AppTheme.sunshine,
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
