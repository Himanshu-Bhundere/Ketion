import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../blocks/domain/entities/block.dart';

part 'visible_block.freezed.dart';

@freezed
class VisibleBlock with _$VisibleBlock {
  const factory VisibleBlock({
    required Block block,
    required int depth,
    @Default(false) bool hasChildren,
    @Default(true) bool isExpanded,
  }) = _VisibleBlock;
}
