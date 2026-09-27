import 'package:freezed_annotation/freezed_annotation.dart';

enum ReminderKind {
  @JsonValue('reminder')
  reminder,
  @JsonValue('alarm')
  alarm,
}
