import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/adaptive_assessment.dart';
import '../../domain/session_result.dart';
import '../../progress/session_history_controller.dart';
import '../../style/palette.dart';
import '../application/family_controller.dart';
import '../application/parent_progress.dart';
import '../content/parent_tips.dart';
import '../navigation/family_navigation.dart';
import '../widgets/accuracy_chart.dart';
import '../widgets/family_widgets.dart';

/// Ebeveyn paneli: çocuğun gidişatını gösterir. Yalnızca okur; oyun
/// verisini değiştirmez.
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette();
    final nickname = context.select<FamilyController, String?>(
      (controller) => controller.profile?.nickname,
    );
    final history = context.watch<SessionHistoryController>();
    final progress = ParentProgress.from(
      results: history.results,
      states: history.learningStates,
    );
    return PopScope(
      // Android geri tuşu ebeveyn bölümünü kilitleyip rol seçimine döner.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(FamilyRoutes.rolePicker);
      },
      child: _buildScaffold(context, palette, nickname, history, progress),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    Palette palette,
    String? nickname,
    SessionHistoryController history,
    ParentProgress progress,
  ) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: palette.backgroundSettings,
        appBar: AppBar(
          backgroundColor: palette.backgroundSettings,
          automaticallyImplyLeading: false,
          title: Text('${nickname ?? 'Çocuğunuz'} — gidişat'),
          actions: [
            IconButton(
              key: const ValueKey('parent-settings'),
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.settings),
              onPressed: () => context.go(FamilyRoutes.parentSettings),
            ),
            IconButton(
              key: const ValueKey('parent-exit'),
              tooltip: 'Çıkış (ebeveyn bölümünü kilitle)',
              icon: const Icon(Icons.logout),
              onPressed: () => context.go(FamilyRoutes.rolePicker),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Özet'),
              Tab(text: 'Seviyeler'),
              Tab(text: 'Geçmiş'),
              Tab(text: 'Gelişim'),
              Tab(text: 'İpuçları'),
            ],
          ),
        ),
        body: Column(
          children: [
            const DevModeBanner(),
            Expanded(
              child: history.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'İlerleme verisi okunamadı.\n${history.errorMessage}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : TabBarView(
                      children: [
                        _SummaryTab(progress: progress),
                        _LevelsTab(progress: progress),
                        _HistoryTab(progress: progress),
                        _GrowthTab(progress: progress),
                        const _TipsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  final List<Widget> children;

  const _TabBody({required this.children});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Palette().darkPen,
          ),
        ),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

const _noDataText =
    'Henüz tamamlanmış bir oturum yok. Çocuğunuz oynadıkça bilgiler burada '
    'görünecek.';

class _SummaryTab extends StatelessWidget {
  final ParentProgress progress;

  const _SummaryTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    final lastPlayed = progress.lastPlayedAt;
    return _TabBody(
      children: [
        FamilyCard(
          title: 'Genel durum',
          children: [
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 12,
              children: [
                _Stat('Oturum', '${progress.totalSessions}'),
                _Stat('Doğru', '${progress.totalCorrect}'),
                _Stat('Yanlış', '${progress.totalWrong}'),
                _Stat('İpucu kullanımı', '${progress.totalHints}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lastPlayed == null
                  ? _noDataText
                  : 'Son oynama: ${formatDateTime(lastPlayed)}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        FamilyCard(
          title: 'Öneri',
          children: [
            Text(parentSuggestion(progress)),
            const SizedBox(height: 8),
            const Text(
              'Bu yalnızca bir öneridir; oyunun işleyişini etkilemez.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ],
    );
  }
}

String _difficultyLabel(AdaptiveDifficulty difficulty) => switch (difficulty) {
  AdaptiveDifficulty.easy => 'Kolay',
  AdaptiveDifficulty.medium => 'Orta',
  AdaptiveDifficulty.hard => 'Zor',
};

String _trendLabel(LearningTrend trend) => switch (trend) {
  LearningTrend.improving => 'Gelişiyor',
  LearningTrend.stable => 'Sabit',
  LearningTrend.declining => 'Geriliyor',
  LearningTrend.notEnoughData => 'Henüz yeterli veri yok',
};

class _LevelsTab extends StatelessWidget {
  final ParentProgress progress;

  const _LevelsTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (!progress.hasData) {
      return const _TabBody(children: [Text(_noDataText)]);
    }
    return _TabBody(
      children: [
        for (final level in progress.levels)
          FamilyCard(
            title: level.levelNumber == null
                ? level.topic
                : 'Seviye ${level.levelNumber}: ${level.topic}',
            children: [
              Text(
                '${level.sessions} oturum • ${level.correct} doğru • '
                '${level.wrong} yanlış • ${level.hintsUsed} ipucu',
                key: ValueKey('level-summary-${level.levelId}'),
              ),
              if (level.adaptiveState case final state?) ...[
                const SizedBox(height: 6),
                Text('Ustalık: %${state.mastery.round()}'),
                Text(
                  'Önerilen zorluk: ${_difficultyLabel(state.currentDifficulty)}',
                ),
                Text('Eğilim: ${_trendLabel(state.latestTrend)}'),
              ],
            ],
          ),
        FamilyCard(
          title: 'Beceriler',
          children: [
            const Text(
              'En çok pratik gerektiren beceri en üstte.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final skill in progress.skills)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SkillLabels.label(skill.tag),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${skill.questions} sorudan ${skill.correct} doğru '
                      '(%${skill.accuracyPercent.round()})',
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: skill.accuracyPercent / 100,
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final ParentProgress progress;

  const _HistoryTab({required this.progress});

  String _duration(SessionResult session) {
    final duration = session.completedAt.difference(session.startedAt);
    if (duration.isNegative) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return minutes == 0 ? ' • $seconds sn' : ' • $minutes dk $seconds sn';
  }

  @override
  Widget build(BuildContext context) {
    if (!progress.hasData) {
      return const _TabBody(children: [Text(_noDataText)]);
    }
    final levelNumbers = {
      for (final level in progress.levels) level.levelId: level.levelNumber,
    };
    return _TabBody(
      children: [
        FamilyCard(
          title: 'Oturum geçmişi',
          children: [
            for (final session in progress.sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(formatDateTime(session.completedAt)),
                subtitle: Text(
                  '${levelNumbers[session.levelId] == null ? session.levelId : 'Seviye ${levelNumbers[session.levelId]}'}'
                  '${_duration(session)}',
                ),
                trailing: Text(
                  '${session.correctCount}/${session.totalQuestions} doğru',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GrowthTab extends StatelessWidget {
  final ParentProgress progress;

  const _GrowthTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    final points = progress.chartPoints();
    return _TabBody(
      children: [
        FamilyCard(
          title: 'Doğruluk (son ${points.isEmpty ? 0 : points.length} oturum)',
          children: [
            AccuracyChart(points: points),
            const SizedBox(height: 8),
            const Text(
              'Her nokta bir oturumdaki doğru cevap oranını gösterir. '
              'İnişler ve çıkışlar normaldir; uzun dönemdeki gidişe bakın.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _TipsTab extends StatelessWidget {
  const _TipsTab();

  @override
  Widget build(BuildContext context) => _TabBody(
    children: [
      for (final tip in ParentTips.tips)
        FamilyCard(title: tip.title, children: [Text(tip.body)]),
      const Text(
        ParentTips.disclaimer,
        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      ),
    ],
  );
}
