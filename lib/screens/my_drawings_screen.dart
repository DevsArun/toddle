import 'dart:io';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/drawing_storage.dart';
import '../widgets/common.dart';
import '../widgets/parental_gate.dart';

class MyDrawingsScreen extends StatelessWidget {
  const MyDrawingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayfulBackground(
      seed: 5,
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
                  const TitlePill(text: 'My Drawings', color: AppTheme.sky),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: DrawingStorage.instance,
                builder: (BuildContext context, Widget? _) {
                  final List<File> files = DrawingStorage.instance.saved;
                  if (files.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.palette_outlined,
                              size: 90, color: Colors.black26),
                          SizedBox(height: 14),
                          Text(
                            'No drawings yet',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Finish a picture and tap Done to save it here.',
                            style: TextStyle(fontSize: 17, color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: files.length,
                    itemBuilder: (BuildContext context, int index) {
                      final File file = files[index];
                      return GlossCard(
                        padding: const EdgeInsets.all(8),
                        radius: 26,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: RoundIconButton(
                                icon: Icons.delete_outline_rounded,
                                size: 46,
                                iconColor: const Color(0xFFD32F2F),
                                onTap: () async {
                                  final bool ok =
                                      await ParentalGate.show(context);
                                  if (ok) {
                                    await DrawingStorage.instance.delete(file);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
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
