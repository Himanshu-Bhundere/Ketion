import 'package:ketion/core/utils/result.dart';

abstract class SyncEngineRepository {
  /// Start a synchronization cycle
  Future<Result<void>> syncNow();

  /// Enqueue an operation and optionally trigger sync
  Future<Result<void>> enqueueOperation(
    String table,
    String entityId,
    String operation, {
    String? payload,
  });
}
