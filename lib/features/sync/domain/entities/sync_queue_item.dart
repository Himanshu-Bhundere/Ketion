import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue_item.freezed.dart';
part 'sync_queue_item.g.dart';

enum SyncQueueItemStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('waiting')
  waiting,
  @JsonValue('failed')
  failed,
  @JsonValue('completed')
  completed,
}

@freezed
class SyncQueueItem with _$SyncQueueItem {
  const factory SyncQueueItem({
    required String id,
    required String entityTable,
    required String entityId,
    required String operation,
    String? payload,
    String? batchId,
    int? version,
    DateTime? updatedAt,
    required DateTime createdAt,
    @Default(SyncQueueItemStatus.pending) SyncQueueItemStatus status,
    @Default(0) int attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    DateTime? leaseUntil,
    String? lastError,
  }) = _SyncQueueItem;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueItemFromJson(json);
}
