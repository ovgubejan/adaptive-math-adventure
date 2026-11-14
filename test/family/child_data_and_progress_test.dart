import 'package:adaptive_math_adventure/domain/adaptive_assessment.dart';
import 'package:adaptive_math_adventure/domain/session_result.dart';
import 'package:adaptive_math_adventure/family/application/parent_progress.dart';
import 'package:adaptive_math_adventure/family/data/child_data_module.dart';
import 'package:adaptive_math_adventure/family/data/key_value_store.dart';
import 'package:adaptive_math_adventure/family/family_module.dart';
import 'package:adaptive_math_adventure/family/screens/role_picker_screen.dart';
import 'package:adaptive_math_adventure/persistence/local_adaptive_progress_repository.dart';
import 'package:adaptive_math_adventure/persistence/local_session_result_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AnswerAttempt _attempt(bool correct, {bool hint = false}) => AnswerAttempt(
  answer: correct ? 1 : 0,
  isCorrect: correct,
  responseTime: const Duration(seconds: 2),
  hintUsed: hint,
);

QuestionEvidence _question(
  String skill,
  List<AnswerAttempt> attempts, {
  String id = 'q',
}) => QuestionEvidence(
  questionId: id,
  skillTag: skill,
  difficulty: 1,
  attempts: attempts,
);

SessionResult _session(
  String id,
  DateTime completedAt,
  List<QuestionEvidence> evidence, {
  String levelId = 'level-01',
}) => SessionResult(
  sessionId: id,
  levelId: levelId,
  startedAt: completedAt.subtract(const Duration(minutes: 2)),
  completedAt: completedAt,
  evidence: evidence,
);

AdaptiveProgressState _state({String? focusSkill}) => AdaptiveProgressState(
  levelId: 'level-01',
  mastery: 62,
  currentDifficulty: AdaptiveDifficulty.medium,
  completedSessionCount: 2,
  recentSessionScores: const [60, 70],
  masterySnapshots: const [],
  skillPerformance: const {},
  completedSessionIds: const ['s1', 's2'],
  successfulMediumSessionCount: 0,
  completedLevelIds: const [],
  latestFocusSkill: focusSkill,
);

void main() {
  group('oyun verisi modülleri (gerçek yerel depolarla)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    final result = _session('s1', DateTime.utc(2026, 11, 14), [
      _question('counting-sets', [_attempt(true)]),
    ]);

    // Bu test, oyun tarafındaki depoların anahtar adları değişirse
    // başarısız olur. O durumda FamilyModule.defaultChildDataModules
    // içindeki anahtarları güncelleyin; aksi hâlde ebeveynin "sil" dediği
    // veri silinmez.
    test('silme kaydı oyun depolarının gerçek verisini kapsar', () async {
      await LocalSessionResultPersistence().saveResult(result);
      await LocalAdaptiveProgressRepository().save(_state());

      final registry = ChildDataRegistry(
        FamilyModule.defaultChildDataModules(SharedPreferencesKeyValueStore()),
      );
      final snapshots = await registry.snapshotAll();
      expect(snapshots.keys, {'sessionResults', 'adaptiveProgress'});

      await registry.clearAll();
      expect(await LocalSessionResultPersistence().loadResults(), isEmpty);
      expect(await LocalAdaptiveProgressRepository().loadAll(), isEmpty);

      await registry.restoreAll(snapshots);
      final restored = await LocalSessionResultPersistence().loadResults();
      expect(restored.single.sessionId, 's1');
      expect(restored.single.correctCount, 1);
      expect(
        (await LocalAdaptiveProgressRepository().loadAll()).single.mastery,
        62,
      );
    });

    // Bu test, çocuğa ait veri yazan ama silme kaydına eklenmemiş bir depo
    // olduğunda başarısız olur. Yeni bir depo eklediyseniz onu
    // FamilyModule.defaultChildDataModules listesine kaydedin ve burada da
    // yazdırın.
    test(
      'oyunun yazdığı her yerel anahtar bir veri modülüne kayıtlıdır',
      () async {
        await LocalSessionResultPersistence().saveResult(result);
        await LocalAdaptiveProgressRepository().save(_state());

        final store = SharedPreferencesKeyValueStore();
        final registry = ChildDataRegistry(
          FamilyModule.defaultChildDataModules(store),
        );
        expect(
          await FamilyModule.unregisteredStorageKeys(store, registry),
          isEmpty,
        );

        await store.write('yeniOyun.skor', '10');
        expect(await FamilyModule.unregisteredStorageKeys(store, registry), {
          'yeniOyun.skor',
        });
      },
    );
  });

  group('StorageKeysDataModule ve kayıt listesi', () {
    test(
      'veri yokken anlık görüntü null; yalnızca kendi anahtarlarına dokunur',
      () async {
        final store = InMemoryKeyValueStore({'baska': 'x'});
        final module = StorageKeysDataModule(
          id: 'm',
          displayName: 'M',
          keys: {'a', 'b'},
          store: store,
        );
        expect(await module.exportSnapshot(), isNull);

        await store.write('a', '1');
        final snapshot = (await module.exportSnapshot())!;
        await module.clear();
        expect(await store.keys(), {'baska'});

        await module.restoreSnapshot(snapshot);
        expect(await store.read('a'), '1');
        expect(await store.read('b'), isNull);
      },
    );

    test('geri yükleme, modüle ait olmayan anahtarları yazmaz', () async {
      final store = InMemoryKeyValueStore();
      final module = StorageKeysDataModule(
        id: 'm',
        displayName: 'M',
        keys: {'a'},
        store: store,
      );
      await module.restoreSnapshot('{"a":"1","family_parent_pin_v1":"kötü"}');
      await module.restoreSnapshot('bozuk json');
      expect(await store.keys(), {'a'});
    });

    test('aynı kimlikle iki modül kaydedilemez', () {
      StorageKeysDataModule module() => StorageKeysDataModule(
        id: 'm',
        displayName: 'M',
        keys: const {},
        store: InMemoryKeyValueStore(),
      );
      expect(
        () => ChildDataRegistry([module(), module()]),
        throwsArgumentError,
      );
    });
  });

  group('ebeveyn paneli hesapları', () {
    final older = _session('s1', DateTime.utc(2026, 11, 10, 9), [
      _question('counting-sets', [_attempt(false), _attempt(true)], id: 'a'),
      _question('number-sequence', [_attempt(false, hint: true)], id: 'b'),
    ]);
    final newer = _session('s2', DateTime.utc(2026, 11, 12, 9), [
      _question('counting-sets', [_attempt(true, hint: true)], id: 'c'),
      _question('number-sequence', [_attempt(false)], id: 'd'),
      _question('number-sequence', const [], id: 'e'),
    ]);

    test('veri yokken boş özet', () {
      final progress = ParentProgress.from(results: const [], states: const []);
      expect(progress.hasData, isFalse);
      expect(progress.totalSessions, 0);
      expect(progress.lastPlayedAt, isNull);
      expect(progress.chartPoints(), isEmpty);
      expect(parentSuggestion(progress), contains('Henüz'));
    });

    test('doğru, yanlış ve ipucu sayıları son denemeye göre hesaplanır', () {
      final progress = ParentProgress.from(
        results: [older, newer],
        states: [_state()],
      );
      expect(progress.totalSessions, 2);
      // Doğru: a (ikinci denemede) ve c. Yanlış: b, d ve hiç cevaplanmayan e.
      expect(progress.totalCorrect, 2);
      expect(progress.totalWrong, 3);
      expect(progress.totalHints, 2);
      expect(progress.lastPlayedAt, newer.completedAt);
      expect(progress.sessions.first.sessionId, 's2');

      final level = progress.levels.single;
      expect(level.levelNumber, 1);
      expect(level.sessions, 2);
      expect(level.correct, 2);
      expect(level.wrong, 3);
      expect(level.hintsUsed, 2);
      expect(level.adaptiveState?.mastery, 62);
    });

    test('beceriler en çok zorlanılandan başlayarak sıralanır', () {
      final progress = ParentProgress.from(
        results: [older, newer],
        states: const [],
      );
      expect(progress.skills.map((skill) => skill.tag), [
        'number-sequence',
        'counting-sets',
      ]);
      expect(progress.skills.first.questions, 3);
      expect(progress.skills.first.correct, 0);
      expect(progress.skills.last.accuracyPercent, 100);
    });

    test('grafik noktaları eskiden yeniye ve en fazla istenen sayıdadır', () {
      final progress = ParentProgress.from(
        results: [newer, older],
        states: const [],
      );
      final points = progress.chartPoints();
      expect(points.map((point) => point.completedAt), [
        older.completedAt,
        newer.completedAt,
      ]);
      expect(points.first.accuracyPercent, 50);
      expect(points.last.accuracyPercent, closeTo(33.3, 0.1));
      expect(
        progress.chartPoints(limit: 1).single.completedAt,
        newer.completedAt,
      );
    });

    test('öneri odak becerisini Türkçe adıyla söyler', () {
      final progress = ParentProgress.from(
        results: [older, newer],
        states: [_state(focusSkill: 'number-sequence')],
      );
      expect(progress.focusSkillTag, 'number-sequence');
      expect(parentSuggestion(progress), contains('Sayı sırası'));
    });

    test('odak becerisi yoksa düşük başarılı beceriden öneri üretir', () {
      final progress = ParentProgress.from(
        results: [older, newer],
        states: const [],
      );
      expect(parentSuggestion(progress), contains('Sayı sırası'));
    });

    test('bilinmeyen beceri etiketi çökmez, okunur hâle getirilir', () {
      expect(SkillLabels.label('counting-sets'), 'Nesneleri sayma');
      expect(SkillLabels.label('yeni-bir-beceri'), 'yeni bir beceri');
      expect(SkillLabels.homeIdea('yeni-bir-beceri'), isNull);
    });

    test('kataloğda olmayan seviye de listelenir', () {
      final progress = ParentProgress.from(
        results: [
          _session('x', DateTime.utc(2026, 11, 1), const [], levelId: 'yeni'),
        ],
        states: const [],
      );
      expect(progress.levels.single.levelNumber, isNull);
      expect(progress.levels.single.topic, 'yeni');
    });
  });

  test('"Ben ...\'yim" eki Türkçe ses uyumuna uyar', () {
    expect(iAmLabel('Ali'), 'Ben Ali\'yim');
    expect(iAmLabel('Ayşe'), 'Ben Ayşe\'yim');
    expect(iAmLabel('Ahmet'), 'Ben Ahmet\'im');
    expect(iAmLabel('Umut'), 'Ben Umut\'um');
    expect(iAmLabel('Gül'), 'Ben Gül\'üm');
    expect(iAmLabel('Ada'), 'Ben Ada\'yım');
    expect(iAmLabel('Işıl'), 'Ben Işıl\'ım');
    expect(iAmLabel(' Test Çocuk '), 'Ben Test Çocuk\'um');
    expect(iAmLabel(''), 'Ben çocuğum');
  });
}
