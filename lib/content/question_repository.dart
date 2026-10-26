import '../domain/activity_type.dart';
import '../domain/math_question.dart';
import '../domain/level_definition.dart';

class QuestionRepository {
  static final List<MathQuestion> _countingQuestions = List.unmodifiable([
    const MathQuestion(
      id: 'count-01',
      levelId: 'level-01',
      activityType: ActivityType.counting,
      skillTag: 'counting-small-sets',
      difficulty: 1,
      data: {
        'prompt': 'How many?',
        'count': 3,
        'answerOptions': [2, 3, 4],
      },
      correctAnswer: 3,
    ),
    const MathQuestion(
      id: 'count-02',
      levelId: 'level-01',
      activityType: ActivityType.counting,
      skillTag: 'counting-small-sets',
      difficulty: 1,
      data: {
        'prompt': 'How many?',
        'count': 5,
        'answerOptions': [4, 5, 6],
      },
      correctAnswer: 5,
    ),
    const MathQuestion(
      id: 'count-03',
      levelId: 'level-01',
      activityType: ActivityType.counting,
      skillTag: 'counting-small-sets',
      difficulty: 2,
      data: {
        'prompt': 'How many?',
        'count': 4,
        'answerOptions': [3, 4, 5],
      },
      correctAnswer: 4,
    ),
    const MathQuestion(
      id: 'count-04',
      levelId: 'level-01',
      activityType: ActivityType.counting,
      skillTag: 'counting-small-sets',
      difficulty: 2,
      data: {
        'prompt': 'How many?',
        'count': 6,
        'answerOptions': [5, 6, 7],
      },
      correctAnswer: 6,
    ),
    const MathQuestion(
      id: 'count-05',
      levelId: 'level-01',
      activityType: ActivityType.counting,
      skillTag: 'counting-small-sets',
      difficulty: 2,
      data: {
        'prompt': 'How many?',
        'count': 2,
        'answerOptions': [1, 2, 3],
      },
      correctAnswer: 2,
    ),
    _choice('count-e-05', 'number-sequence', 1, 'What number comes after 3?', [
      2,
      4,
      5,
    ], 4),
    _choice('count-e-06', 'number-sequence', 1, 'What number comes before 6?', [
      5,
      7,
      4,
    ], 5),
    _choice('count-e-07', 'one-more-less', 1, 'What is one more than 4?', [
      3,
      5,
      6,
    ], 5),
    _drag('count-e-08', 'missing-quantity', 1, '3 counters and ? make 5.', [
      1,
      2,
      3,
    ], 2),
    _drag('count-e-09', 'missing-quantity', 1, '2 counters and ? make 4.', [
      1,
      2,
      3,
    ], 2),
    _drag('count-e-10', 'missing-quantity', 1, '4 counters and ? make 6.', [
      1,
      2,
      3,
    ], 2),
    _count('count-m-01', 'counting-sets', 2, 6),
    _count('count-m-02', 'counting-sets', 2, 7),
    _count('count-m-03', 'counting-sets', 2, 8),
    _count('count-m-04', 'counting-sets', 2, 9),
    _choice('count-m-05', 'number-sequence', 2, 'What number comes after 12?', [
      11,
      13,
      14,
    ], 13),
    _choice(
      'count-m-06',
      'number-sequence',
      2,
      'What number comes before 10?',
      [8, 9, 11],
      9,
    ),
    _choice('count-m-07', 'one-more-less', 2, 'What is one less than 8?', [
      6,
      7,
      9,
    ], 7),
    _drag('count-m-08', 'missing-quantity', 2, '5 counters and ? make 8.', [
      2,
      3,
      4,
    ], 3),
    _drag('count-m-09', 'missing-quantity', 2, '6 counters and ? make 9.', [
      2,
      3,
      4,
    ], 3),
    _drag('count-m-10', 'missing-quantity', 2, '7 counters and ? make 10.', [
      2,
      3,
      4,
    ], 3),
    _count('count-h-01', 'counting-sets', 3, 10),
    _count('count-h-02', 'counting-sets', 3, 12),
    _count('count-h-03', 'counting-sets', 3, 15),
    _count('count-h-04', 'counting-sets', 3, 18),
    _choice('count-h-05', 'number-sequence', 3, 'What number comes after 19?', [
      18,
      20,
      21,
    ], 20),
    _choice(
      'count-h-06',
      'number-sequence',
      3,
      'What number comes before 16?',
      [14, 15, 17],
      15,
    ),
    _choice('count-h-07', 'one-more-less', 3, 'What is one less than 14?', [
      12,
      13,
      15,
    ], 13),
    _drag('count-h-08', 'missing-quantity', 3, '8 counters and ? make 13.', [
      4,
      5,
      6,
    ], 5),
    _drag('count-h-09', 'missing-quantity', 3, '9 counters and ? make 15.', [
      5,
      6,
      7,
    ], 6),
    _drag('count-h-10', 'missing-quantity', 3, '7 counters and ? make 16.', [
      8,
      9,
      10,
    ], 9),
    _choice('count-h-11', 'one-more-less', 3, 'What is one more than 17?', [
      16,
      18,
      19,
    ], 18),
    _choice('count-h-12', 'one-more-less', 3, 'What is one less than 20?', [
      18,
      19,
      20,
    ], 19),
    _drag('count-h-13', 'missing-quantity', 3, '6 counters and ? make 14.', [
      7,
      8,
      9,
    ], 8),
    _count('count-h-14', 'counting-sets', 3, 20),
    _choice(
      'count-h-15',
      'number-sequence',
      3,
      'What number comes before 18?',
      [16, 17, 19],
      17,
    ),
  ]);

  static const demoQuestions = [
    MathQuestion(
      id: 'demo-add-01',
      levelId: 'activity-demo',
      activityType: ActivityType.multipleChoice,
      skillTag: 'addition-within-10',
      difficulty: 1,
      data: {
        'prompt': '3 + 2 = ?',
        'answerOptions': [4, 5, 6],
      },
      correctAnswer: 5,
    ),
    MathQuestion(
      id: 'demo-subtract-01',
      levelId: 'activity-demo',
      activityType: ActivityType.multipleChoice,
      skillTag: 'subtraction-within-10',
      difficulty: 1,
      data: {
        'prompt': '8 - 3 = ?',
        'answerOptions': [4, 5, 6],
      },
      correctAnswer: 5,
    ),
    MathQuestion(
      id: 'demo-drag-01',
      levelId: 'activity-demo',
      activityType: ActivityType.dragAndDrop,
      skillTag: 'missing-addend-within-10',
      difficulty: 2,
      data: {
        'prompt': '2 + ? = 5',
        'answerOptions': [2, 3, 4],
      },
      correctAnswer: 3,
    ),
  ];

  List<MathQuestion> questionsFor(LevelDefinition level) {
    if (level.questionSetReference == 'counting-level-1') {
      return _countingQuestions;
    }
    return const [];
  }
}

MathQuestion _count(String id, String skill, int difficulty, int count) =>
    MathQuestion(
      id: id,
      levelId: 'level-01',
      activityType: ActivityType.counting,
      skillTag: skill,
      difficulty: difficulty,
      data: {
        'prompt': 'How many?',
        'count': count,
        'answerOptions': [count - 1, count, count + 1],
      },
      correctAnswer: count,
    );

MathQuestion _choice(
  String id,
  String skill,
  int difficulty,
  String prompt,
  List<int> options,
  int answer,
) => MathQuestion(
  id: id,
  levelId: 'level-01',
  activityType: ActivityType.multipleChoice,
  skillTag: skill,
  difficulty: difficulty,
  data: {'prompt': prompt, 'answerOptions': options},
  correctAnswer: answer,
);

MathQuestion _drag(
  String id,
  String skill,
  int difficulty,
  String prompt,
  List<int> options,
  int answer,
) => MathQuestion(
  id: id,
  levelId: 'level-01',
  activityType: ActivityType.dragAndDrop,
  skillTag: skill,
  difficulty: difficulty,
  data: {'prompt': prompt, 'answerOptions': options},
  correctAnswer: answer,
);
