import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/catalog.dart';
import '../services/entitlement_service.dart';
import '../widgets/common.dart';
import '../widgets/parental_gate.dart';
import 'unlock_screen.dart';

/// Everything a grown-up needs, always behind the gate.
class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  bool _unlocked = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool ok = await ParentalGate.show(context);
      if (!mounted) return;
      setState(() {
        _unlocked = ok;
        _checked = true;
      });
      if (!ok && mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_unlocked) {
      return const PlayfulBackground(child: SizedBox.expand());
    }

    return PlayfulBackground(
      seed: 21,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 10),
              child: Row(
                children: <Widget>[
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  const TitlePill(text: 'Parents', color: AppTheme.brandDark),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: AnimatedBuilder(
                      animation: EntitlementService.instance,
                      builder: (BuildContext context, Widget? _) {
                        final bool premium =
                            EntitlementService.instance.isPremium;
                        return Column(
                          children: <Widget>[
                            GlossCard(
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    premium
                                        ? Icons.verified_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 44,
                                    color: premium
                                        ? AppTheme.grass
                                        : const Color(0xFF7E57C2),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          premium
                                              ? 'Full library unlocked'
                                              : 'Free version',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          premium
                                              ? 'All ${Catalog.totalPages} pictures are available.'
                                              : '${Catalog.totalFreePages} of ${Catalog.totalPages} pictures available.',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!premium)
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const UnlockScreen(),
                                        ),
                                      ),
                                      child: const Text('Unlock'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GlossCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Purchases',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'The full library is a single payment tied to '
                                    'your Amazon account. Reinstalling the app or '
                                    'using another Fire tablet with the same '
                                    'account keeps the pictures unlocked.',
                                    style: TextStyle(fontSize: 16.5),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: <Widget>[
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final bool ok =
                                              await EntitlementService.instance
                                                  .restore();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(ok
                                                  ? 'Purchase restored.'
                                                  : 'No previous purchase found.'),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.restore_rounded),
                                        label:
                                            const Text('Restore purchase'),
                                      ),
                                    ],
                                  ),
                                  // Shows exactly what Amazon last replied, so
                                  // a failed purchase can be diagnosed without
                                  // guessing. Hidden until something happens.
                                  if (EntitlementService.instance.lastStatus !=
                                      null) ...<Widget>[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Amazon status: '
                                      '${EntitlementService.instance.lastStatus}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.ink.withOpacity(0.55),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const GlossCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Privacy',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'This app collects nothing. There are no ads, '
                                    'no analytics, no accounts, no chat and no '
                                    'links out of the app. Drawings never leave '
                                    'the tablet. The app works fully offline.',
                                    style: TextStyle(fontSize: 16.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const GlossCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Tips for little artists',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Start with the Fill tool: one tap colors a '
                                    'whole shape. The Brush and Marker are great '
                                    'for scribbling on top, and Undo always brings '
                                    'the picture back.',
                                    style: TextStyle(fontSize: 16.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
