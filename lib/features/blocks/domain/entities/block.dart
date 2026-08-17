import 'package:freezed_annotation/freezed_annotation.dart';

part 'block.freezed.dart';
part 'block.g.dart';

@freezed
class Block with _$Block {
  const factory Block({
    required String id,
    required String pageId,
    String? parentBlockId,
    required String type,
    required double position,
    required String data,
    @Default(1) int version,
    @Default(false) bool deleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Block;

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
}
