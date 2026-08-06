import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../data/catalog.dart';
import '../services/entitlement_service.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'my_drawings_screen.dart';
import 'parents_screen.dart';
import 'unlock_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayfulBackground(
      seed: 11,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const _HomeHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final int columns = constraints.maxWidth > 1100
                      ? 4
                      : constraints.maxWidth > 720
                          ? 3
                          : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: Catalog.categories.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _CategoryTile(
                      category: Catalog.categories[index],
                      index: index,
                    ),
                  );
                },
              ),
            ),
            const _UnlockStrip(),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFFFB74D), Color(0xFFFF7043)],
              ),
            ),
            child: const Icon(Icons.palette_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Pick a picture',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Tap a box to start coloring',
                  style: TextStyle(fontSize: 17, color: Colors.black54),
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.collections_rounded,
            tooltip: 'My drawings',
            color: Colors.white,
            iconColor: AppTheme.sky,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MyDrawingsScreen(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          RoundIconButton(
            icon: Icons.family_restroom_rounded,
            tooltip: 'Parents',
            color: Colors.white,
            iconColor: AppTheme.brandDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ParentsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.index});

  final ColoringCategory category;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SquishButton(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CategoryScreen(category: category),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              category.color.withOpacity(0.95),
              Color.lerp(category.color, Colors.white, 0.35)!,
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: category.color.withOpacity(0.38),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                category.icon,
                size: 130,
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(category.icon, size: 34, color: category.color),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${category.pages.length} pictures',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockStrip extends StatelessWidget {
  const _UnlockStrip();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: EntitlementService.instance,
      builder: (BuildContext context, Widget? _) {
        if (EntitlementService.instance.isPremium) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: SquishButton(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const UnlockScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF5C6BC0), Color(0xFF7E57C2)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF5C6BC0).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Unlock all pictures',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${Catalog.totalPages} pictures - one time '
                          '${EntitlementService.priceLabel} - no ads',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 34),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
