import 'package:freezed_annotation/freezed_annotation.dart';

part 'assistive_ball_state.freezed.dart';
part 'assistive_ball_state.g.dart';

@freezed
class AssistiveBallState with _$AssistiveBallState {
  const factory AssistiveBallState({
    @Default(false) bool isEnabled,
    @Default(true) bool isVisible,
    @Default(1.0) double normalizedX,
    @Default(1.0) double normalizedY,
    @Default(false) bool isMenuOpen,
    @Default(false) bool isFloatingNoteOpen,
    @Default(false) bool isNoteSelectorOpen,
    String? activePageId,
    @Default(340.0) double floatingNoteWidth,
    @Default(420.0) double floatingNoteHeight,
    @Default(0.5) double floatingNoteNormalizedX,
    @Default(0.4) double floatingNoteNormalizedY,
    @Default(false) bool isNoteMinimized,
    @Default(false) bool isStandaloneOverlay,
  }) = _AssistiveBallState;

  factory AssistiveBallState.fromJson(Map<String, dynamic> json) =>
      _$AssistiveBallStateFromJson(json);
}
