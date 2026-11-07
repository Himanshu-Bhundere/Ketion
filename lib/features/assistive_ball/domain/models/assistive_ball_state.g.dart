// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistive_ball_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssistiveBallStateImpl _$$AssistiveBallStateImplFromJson(
        Map<String, dynamic> json) =>
    _$AssistiveBallStateImpl(
      isEnabled: json['isEnabled'] as bool? ?? false,
      isVisible: json['isVisible'] as bool? ?? true,
      normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.92,
      normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.65,
      isMenuOpen: json['isMenuOpen'] as bool? ?? false,
      isFloatingNoteOpen: json['isFloatingNoteOpen'] as bool? ?? false,
      activePageId: json['activePageId'] as String?,
      floatingNoteWidth:
          (json['floatingNoteWidth'] as num?)?.toDouble() ?? 340.0,
      floatingNoteHeight:
          (json['floatingNoteHeight'] as num?)?.toDouble() ?? 420.0,
      floatingNoteNormalizedX:
          (json['floatingNoteNormalizedX'] as num?)?.toDouble() ?? 0.5,
      floatingNoteNormalizedY:
          (json['floatingNoteNormalizedY'] as num?)?.toDouble() ?? 0.4,
      isNoteMinimized: json['isNoteMinimized'] as bool? ?? false,
    );

Map<String, dynamic> _$$AssistiveBallStateImplToJson(
        _$AssistiveBallStateImpl instance) =>
    <String, dynamic>{
      'isEnabled': instance.isEnabled,
      'isVisible': instance.isVisible,
      'normalizedX': instance.normalizedX,
      'normalizedY': instance.normalizedY,
      'isMenuOpen': instance.isMenuOpen,
      'isFloatingNoteOpen': instance.isFloatingNoteOpen,
      'activePageId': instance.activePageId,
      'floatingNoteWidth': instance.floatingNoteWidth,
      'floatingNoteHeight': instance.floatingNoteHeight,
      'floatingNoteNormalizedX': instance.floatingNoteNormalizedX,
      'floatingNoteNormalizedY': instance.floatingNoteNormalizedY,
      'isNoteMinimized': instance.isNoteMinimized,
    };
