import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../coloring/coloring_painter.dart';
import '../data/art_library.dart';
import '../data/catalog.dart';
import '../models/art.dart';
import '../services/entitlement_service.dart';
import '../widgets/common.dart';
import 'coloring_screen.dart';
import 'unlock_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final ColoringCategory category;

  @override
  Widget build(BuildContext context) {
    return PlayfulBackground(
      seed: category.id.hashCode,
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
                  Expanded(child: TitlePill(text: category.title, color: category.color)),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: EntitlementService.instance,
                builder: (BuildContext context, Widget? _) {
                  final bool premium = EntitlementService.instance.isPremium;
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      final int columns = c.maxWidth > 1100
                          ? 5
                          : c.maxWidth > 800
                              ? 4
                              : 3;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: category.pages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ColoringPage page = category.pages[index];
                          final bool locked = !page.isFree && !premium;
                          return _PageTile(page: page, locked: locked);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({required this.page, required this.locked});

  final ColoringPage page;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final ArtDef art = ArtLibrary.build(page.shapeKey);
    return SquishButton(
      onTap: () {
        if (locked) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const UnlockScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ColoringScreen(page: page),
            ),
          );
        }
      },
      child: GlossCard(
        padding: const EdgeInsets.all(10),
        radius: 28,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: ThumbnailPainter(art: art, showColor: false),
              ),
            ),
            if (locked)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.white.withOpacity(0.72),
                  child: const Center(
                    child: Icon(Icons.lock_rounded,
                        size: 44, color: Color(0xFF7E57C2)),
                  ),
                ),
              ),
            if (page.isFree)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.grass,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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
