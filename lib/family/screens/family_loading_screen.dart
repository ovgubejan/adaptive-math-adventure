import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../style/palette.dart';
import '../application/family_controller.dart';

/// Kayıtlı durum okunurken gösterilen açılış ekranı.
class FamilyLoadingScreen extends StatelessWidget {
  const FamilyLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FamilyController>();
    final error = controller.loadError;
    return Scaffold(
      backgroundColor: Palette().backgroundMain,
      body: Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: controller.load,
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
