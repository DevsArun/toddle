import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/catalog.dart';
import '../services/entitlement_service.dart';
import '../widgets/common.dart';
import '../widgets/parental_gate.dart';

/// The single purchase screen. Everything here is written for the parent, and
/// the buy button is always behind the parental gate.
class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  Future<void> _buy(BuildContext context) async {
    final bool passed = await ParentalGate.show(context);
    if (!passed || !context.mounted) return;

    final bool ok = await EntitlementService.instance.purchase();
    if (!context.mounted) return;

    if (ok) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('All pictures unlocked'),
          content: Text(
            'Thank you! All ${Catalog.totalPages} pictures are now available on '
            'this Amazon account.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Start coloring'),
            ),
          ],
        ),
      );
      if (context.mounted) Navigator.of(context).pop();
    } else {
      final String? error = EntitlementService.instance.lastError;
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final bool ok = await EntitlementService.instance.restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Your purchase was restored.'
              : EntitlementService.instance.lastError ??
                  'No previous purchase found.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulBackground(
      seed: 42,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: EntitlementService.instance,
          builder: (BuildContext context, Widget? _) {
            final EntitlementService svc = EntitlementService.instance;
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 20, 4),
                  child: Row(
                    children: <Widget>[
                      RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: GlossCard(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Color(0xFF5C6BC0),
                                      Color(0xFF7E57C2),
                                    ],
                                  ),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    size: 46, color: Colors.white),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Unlock the full picture library',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'One payment. No subscription. No ads. Ever.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const _Bullet(
                                icon: Icons.brush_rounded,
                                text: 'All 600 pictures in 30 picture packs',
                              ),
                              const _Bullet(
                                icon: Icons.wifi_off_rounded,
                                text: 'Works completely offline',
                              ),
                              const _Bullet(
                                icon: Icons.shield_moon_rounded,
                                text: 'No ads, no links, no sign in',
                              ),
                              const _Bullet(
                                icon: Icons.devices_rounded,
                                text:
                                    'Tied to your Amazon account on every Fire tablet',
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      svc.busy ? null : () => _buy(context),
                                  icon: svc.busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.lock_open_rounded),
                                  label: Text(
                                    svc.busy
                                        ? 'Please wait...'
                                        : 'Unlock for ${EntitlementService.priceLabel}',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed:
                                    svc.busy ? null : () => _restore(context),
                                icon: const Icon(Icons.restore_rounded),
                                label: const Text('Restore purchase'),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Purchases are handled securely by the Amazon '
                                'Appstore and are protected by a grown-up check.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.sky.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.brandDark, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 17.5)),
          ),
        ],
      ),
    );
  }
}
