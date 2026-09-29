import 'package:freezed_annotation/freezed_annotation.dart';

part 'drop_intent.freezed.dart';

@freezed
sealed class DropIntent with _$DropIntent {
  const factory DropIntent.before(String targetBlockId) = DropIntentBefore;
  const factory DropIntent.after(String targetBlockId) = DropIntentAfter;
  const factory DropIntent.child(String targetBlockId) = DropIntentChild;
  const factory DropIntent.unnest(String targetBlockId) = DropIntentUnnest;
}
