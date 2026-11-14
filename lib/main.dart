import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'family/family_module.dart';
import 'persistence/adaptive_progress_repository.dart';
import 'persistence/local_adaptive_progress_repository.dart';
import 'persistence/local_session_result_persistence.dart';
import 'persistence/session_result_persistence.dart';
import 'progress/session_history_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final persistence = LocalSessionResultPersistence();
  final adaptiveProgress = LocalAdaptiveProgressRepository();
  // Ebeveyn modülü (kurulum, rıza, PIN, ebeveyn paneli): lib/family/
  final family = FamilyModule.local()..start();
  runApp(
    MultiProvider(
      providers: [
        Provider<SessionResultPersistence>.value(value: persistence),
        Provider<AdaptiveProgressRepository>.value(value: adaptiveProgress),
        ChangeNotifierProvider(
          create: (_) =>
              SessionHistoryController(persistence, adaptiveProgress)..load(),
        ),
        ...family.providers,
      ],
      child: const AdaptiveMathAdventureApp(),
    ),
  );
}
