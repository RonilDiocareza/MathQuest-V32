import 'package:flame/components.dart';
import 'dart:math';
import '../worksheet_lesson_data.dart';

class QuestionNpcPlacement {
  static const double physicalCollisionRadius = 8;

  final int level;
  final int questionNumber;
  final String questionId;
  final String topic;
  final Vector2 position;
  final String spriteAssetPath;
  final double collisionRadius;
  final int questionSeed;

  const QuestionNpcPlacement({
    this.level = 1,
    this.questionNumber = 1,
    required this.questionId,
    required this.topic,
    required this.position,
    this.spriteAssetPath = 'assets/images/npcs/np1.png',
    this.collisionRadius = physicalCollisionRadius,
    this.questionSeed = 0,
  });
}

class NpcQuestion {
  final String id;
  final int questionNumber;
  final String semester;
  final String module;
  final String lesson;
  final String topic;
  final String prompt;
  final List<String> choices;
  final int correctAnswerIndex;

  const NpcQuestion({
    required this.id,
    this.questionNumber = 1,
    this.semester = '',
    this.module = '',
    this.lesson = '',
    required this.topic,
    required this.prompt,
    required this.choices,
    required this.correctAnswerIndex,
  });

  NpcQuestion withTopic(String topic) => NpcQuestion(
        id: id,
        questionNumber: questionNumber,
        semester: semester,
        module: module,
        lesson: lesson,
        topic: topic,
        prompt: prompt,
        choices: choices,
        correctAnswerIndex: correctAnswerIndex,
      );

  static final List<NpcQuestion> all = List.generate(
    6,
    (index) => _questionForWorksheet(worksheetLessons[index], index + 1, 0),
    growable: false,
  );

  // Tiled-world coordinates for the four building entrances, central shrine,
  // and final NPC on the southern road near the map edge.
  static const List<(double, double)> _mapNpcPositions = [
    (535, 285),
    (1062, 340),
    (397, 553),
    (651, 584),
    (1120, 550),
    (468, 1016),
  ];

  static const List<String> _npcSpritePaths = [
    'assets/images/npcs/np1.png',
    'assets/images/npcs/npc2.png',
    'assets/images/npcs/npc3.png',
    'assets/images/npcs/npc4.png',
    'assets/images/npcs/npc5.png',
    'assets/images/npcs/npc6.png',
  ];

  static List<QuestionNpcPlacement> createNpcPlacements({
    required Vector2 playerSpawn,
    required bool Function(Vector2 center, double radius) canOccupy,
    int level = 1,
    Random? random,
  }) {
    final placements = <QuestionNpcPlacement>[];

    bool isClear(Vector2 feetPosition) {
      final radius = QuestionNpcPlacement.physicalCollisionRadius;
      final center = Vector2(feetPosition.x, feetPosition.y - radius);
      if (!canOccupy(center, radius)) return false;

      final playerFeet = Vector2(playerSpawn.x, playerSpawn.y + 21);
      if (center.distanceTo(playerFeet) < radius * 2 + 4) return false;

      return placements.every((placement) {
        final otherCenter = Vector2(
          placement.position.x,
          placement.position.y - placement.collisionRadius,
        );
        return center.distanceTo(otherCenter) >=
            radius + placement.collisionRadius + 4;
      });
    }

    for (var index = 0; index < _mapNpcPositions.length; index++) {
      final (x, y) = _mapNpcPositions[index];
      final position = Vector2(x, y);
      if (!isClear(position)) {
        throw StateError(
          'Question NPC ${index + 1} cannot be placed safely at its building door.',
        );
      }
      final questionSeed = random?.nextInt(1 << 31) ?? 0;
      placements.add(_placementAt(index, position, level, questionSeed));
    }

    if (placements.length != all.length) {
      throw StateError(
        'Only ${placements.length} of ${all.length} NPCs have a safe map location.',
      );
    }

    return placements;
  }

  static QuestionNpcPlacement _placementAt(
    int index,
    Vector2 position,
    int level,
    int questionSeed,
  ) {
    final question = forLevel(index + 1, level, questionSeed: questionSeed);
    return QuestionNpcPlacement(
      level: level,
      questionNumber: question.questionNumber,
      questionId: question.id,
      topic: question.topic,
      position: position,
      spriteAssetPath: _npcSpritePaths[index],
      questionSeed: questionSeed,
    );
  }

  static NpcQuestion? forPlacement(QuestionNpcPlacement placement) {
    final original = all.firstWhere(
      (question) =>
          question.id == placement.questionId &&
          question.questionNumber == placement.questionNumber,
      orElse: () => all.first,
    );
    if (original.id != placement.questionId ||
        original.questionNumber != placement.questionNumber) {
      return null;
    }
    return forLevel(
      placement.questionNumber,
      placement.level,
      questionSeed: placement.questionSeed,
    ).withTopic(placement.topic);
  }

  static NpcQuestion forLevel(
    int questionNumber,
    int level, {
    int? questionSeed,
  }) {
    if (questionNumber < 1 || questionNumber > all.length) {
      throw ArgumentError.value(questionNumber, 'questionNumber');
    }
    if (level < 1 || level > 60) {
      throw ArgumentError.value(level, 'level');
    }
    final worksheetIndex = ((level - 1) * all.length + questionNumber - 1) %
        worksheetLessons.length;
    final seed = questionSeed ?? level * 101 + questionNumber;
    return _questionForWorksheet(
      worksheetLessons[worksheetIndex],
      questionNumber,
      seed,
    );
  }

  static NpcQuestion _questionForWorksheet(
    WorksheetLesson lesson,
    int questionNumber,
    int choiceSeed,
  ) {
    final choices = [...lesson.choices]..shuffle(Random(choiceSeed));
    return NpcQuestion(
      id: 'npc_question_$questionNumber',
      questionNumber: questionNumber,
      semester: lesson.semester,
      module: lesson.topic,
      lesson: lesson.title,
      topic: lesson.topic,
      prompt: lesson.question,
      choices: choices,
      correctAnswerIndex: choices.indexOf(lesson.correctAnswer),
    );
  }
}
