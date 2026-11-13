import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/main.dart';

void main() {
  test('StudyTask serializes and restores its data', () {
    final task = StudyTask(
      title: 'Read chapter one',
      subject: 'Physics',
      dueDate: DateTime(2026, 11, 13),
      isDone: true,
    );

    final restored = StudyTask.fromJson(task.toJson());

    expect(restored.title, 'Read chapter one');
    expect(restored.subject, 'Physics');
    expect(restored.dueDate, DateTime(2026, 11, 13));
    expect(restored.isDone, isTrue);
  });
}
