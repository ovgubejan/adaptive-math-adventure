import '../../content/level_catalog.dart';
import '../../domain/adaptive_assessment.dart';
import '../../domain/session_result.dart';

/// Ebeveyn panelinde gösterilen özetlerin hesaplandığı yer.
///
/// Yalnızca OKUR: mevcut oturum sonuçlarını ve uyarlama durumunu alır,
/// hiçbir şeyi değiştirmez. Arayüzden bağımsızdır, bu yüzden doğrudan test
/// edilebilir.

class LevelProgress {
  final String levelId;
  final int? levelNumber;
  final String topic;
  final int sessions;
  final int correct;
  final int wrong;
  final int hintsUsed;
  final DateTime? lastPlayedAt;

  /// Uyarlama motorunun bu seviye için durumu (henüz yoksa `null`).
  final AdaptiveProgressState? adaptiveState;

  const LevelProgress({
    required this.levelId,
    required this.levelNumber,
    required this.topic,
    required this.sessions,
    required this.correct,
    required this.wrong,
    required this.hintsUsed,
    required this.lastPlayedAt,
    required this.adaptiveState,
  });

  int get answered => correct + wrong;
}

class SkillProgress {
  final String tag;
  final int questions;
  final int correct;

  const SkillProgress({
    required this.tag,
    required this.questions,
    required this.correct,
  });

  int get wrong => questions - correct;

  double get accuracyPercent => questions == 0 ? 0 : correct / questions * 100;
}

class SessionPoint {
  final DateTime completedAt;
  final double accuracyPercent;

  const SessionPoint(this.completedAt, this.accuracyPercent);
}

class ParentProgress {
  /// En yeni oturum en başta.
  final List<SessionResult> sessions;
  final int totalCorrect;
  final int totalWrong;
  final int totalHints;
  final List<LevelProgress> levels;

  /// En çok zorlanılandan en başarılıya doğru sıralı.
  final List<SkillProgress> skills;

  /// Uyarlama motorunun son oturumdan sonra önerdiği odak becerisi.
  final String? focusSkillTag;

  const ParentProgress({
    required this.sessions,
    required this.totalCorrect,
    required this.totalWrong,
    required this.totalHints,
    required this.levels,
    required this.skills,
    required this.focusSkillTag,
  });

  int get totalSessions => sessions.length;

  bool get hasData => sessions.isNotEmpty;

  DateTime? get lastPlayedAt =>
      sessions.isEmpty ? null : sessions.first.completedAt;

  /// Grafik için: eskiden yeniye son [limit] oturumun doğruluk yüzdesi.
  List<SessionPoint> chartPoints({int limit = 12}) {
    final recent = sessions.take(limit).toList().reversed;
    return [
      for (final session in recent)
        SessionPoint(session.completedAt, session.accuracy * 100),
    ];
  }

  factory ParentProgress.from({
    required List<SessionResult> results,
    required List<AdaptiveProgressState> states,
  }) {
    final sessions = [...results]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final levelIds = <String>[];
    final skillQuestions = <String, int>{};
    final skillCorrect = <String, int>{};
    var totalCorrect = 0;
    var totalWrong = 0;
    var totalHints = 0;
    for (final session in sessions) {
      if (!levelIds.contains(session.levelId)) levelIds.add(session.levelId);
      totalCorrect += session.correctCount;
      totalWrong += session.totalQuestions - session.correctCount;
      totalHints += _hintsIn(session);
      for (final evidence in session.evidence) {
        skillQuestions.update(
          evidence.skillTag,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (evidence.finalAttempt?.isCorrect ?? false) {
          skillCorrect.update(
            evidence.skillTag,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    final levels = [
      for (final levelId in levelIds)
        _levelProgress(
          levelId,
          sessions.where((item) => item.levelId == levelId).toList(),
          states.where((item) => item.levelId == levelId).firstOrNull,
        ),
    ]..sort((a, b) => (a.levelNumber ?? 9999).compareTo(b.levelNumber ?? 9999));

    final skills =
        [
          for (final entry in skillQuestions.entries)
            SkillProgress(
              tag: entry.key,
              questions: entry.value,
              correct: skillCorrect[entry.key] ?? 0,
            ),
        ]..sort((a, b) {
          final byAccuracy = a.accuracyPercent.compareTo(b.accuracyPercent);
          return byAccuracy != 0 ? byAccuracy : a.tag.compareTo(b.tag);
        });

    final latestLevelId = sessions.isEmpty ? null : sessions.first.levelId;
    final focusSkillTag = states
        .where((item) => item.levelId == latestLevelId)
        .firstOrNull
        ?.latestFocusSkill;

    return ParentProgress(
      sessions: List.unmodifiable(sessions),
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      totalHints: totalHints,
      levels: List.unmodifiable(levels),
      skills: List.unmodifiable(skills),
      focusSkillTag: focusSkillTag,
    );
  }

  static LevelProgress _levelProgress(
    String levelId,
    List<SessionResult> sessions,
    AdaptiveProgressState? state,
  ) {
    final level = LevelCatalog.byId(levelId);
    var correct = 0;
    var wrong = 0;
    var hints = 0;
    for (final session in sessions) {
      correct += session.correctCount;
      wrong += session.totalQuestions - session.correctCount;
      hints += _hintsIn(session);
    }
    return LevelProgress(
      levelId: levelId,
      levelNumber: level?.number,
      topic: level?.learningTopic ?? levelId,
      sessions: sessions.length,
      correct: correct,
      wrong: wrong,
      hintsUsed: hints,
      lastPlayedAt: sessions.isEmpty ? null : sessions.first.completedAt,
      adaptiveState: state,
    );
  }

  static int _hintsIn(SessionResult session) => session.evidence.fold(
    0,
    (total, item) =>
        total + item.attempts.where((attempt) => attempt.hintUsed).length,
  );
}

/// Beceri etiketlerinin ebeveyne gösterilen Türkçe adları ve evde yapılabilecek
/// küçük etkinlik önerileri.
///
/// OYUN/SEVİYE EKİBİ İÇİN: Yeni bir `skillTag` eklerseniz buraya Türkçe adını
/// da ekleyin. Eklemezseniz etiket olduğu gibi (tireleri boşluk yapılarak)
/// gösterilir; uygulama bozulmaz.
class SkillLabels {
  const SkillLabels._();

  static const Map<String, String> _labels = {
    'counting-small-sets': 'Küçük grupları sayma',
    'counting-sets': 'Nesneleri sayma',
    'number-sequence': 'Sayı sırası (önceki / sonraki)',
    'one-more-less': 'Bir fazla / bir eksik',
    'missing-quantity': 'Eksik miktarı bulma',
    'addition-within-10': '10\'a kadar toplama',
    'subtraction-within-10': '10\'a kadar çıkarma',
    'missing-addend-within-10': 'Eksik toplananı bulma',
  };

  static const Map<String, String> _homeIdeas = {
    'counting-small-sets':
        'Günlük hayatta küçük grupları birlikte sayabilirsiniz: tabaktaki '
        'meyveler, masadaki kaşıklar.',
    'counting-sets':
        'Daha kalabalık grupları sayarken nesnelere tek tek dokunarak '
        'saymayı deneyebilirsiniz.',
    'number-sequence':
        'Merdiven çıkarken basamakları sayıp "şimdi hangisi geliyor?" diye '
        'sorabilirsiniz.',
    'one-more-less':
        '"Bir tane daha koyarsam kaç olur? Bir tane alırsam?" oyununu '
        'oyuncaklarla oynayabilirsiniz.',
    'missing-quantity':
        'Birkaç nesneden birini saklayıp "kaç tane eksik?" diye '
        'sorabilirsiniz.',
    'addition-within-10':
        'İki küçük grubu birleştirip toplamı birlikte sayabilirsiniz.',
    'subtraction-within-10':
        'Bir gruptan birkaç nesne ayırıp "kaç tane kaldı?" diye '
        'sorabilirsiniz.',
    'missing-addend-within-10':
        '"Elimde 3 var, 5 olması için kaç tane daha lazım?" gibi sorularla '
        'oynayabilirsiniz.',
  };

  static String label(String tag) => _labels[tag] ?? tag.replaceAll('-', ' ');

  static String? homeIdea(String tag) => _homeIdeas[tag];
}

/// Ebeveyne gösterilen, kural tabanlı kısa öneri. Yalnızca öneridir;
/// uygulamadaki hiçbir davranış buna bağlı değildir.
String parentSuggestion(ParentProgress progress) {
  if (!progress.hasData) {
    return 'Henüz tamamlanmış bir oturum yok. Çocuğunuz ilk oturumunu '
        'bitirdiğinde burada kısa bir öneri göreceksiniz.';
  }
  final focus =
      progress.focusSkillTag ??
      progress.skills
          .where((skill) => skill.questions >= 3 && skill.accuracyPercent < 70)
          .firstOrNull
          ?.tag;
  if (focus == null) {
    return 'Şu an belirgin bir zorlanma görünmüyor. Kısa ve düzenli '
        'oturumlarla devam edebilirsiniz.';
  }
  final idea = SkillLabels.homeIdea(focus);
  return 'Şu sıralar biraz daha pratik iyi gelebilecek konu: '
      '${SkillLabels.label(focus)}.${idea == null ? '' : ' $idea'}';
}
