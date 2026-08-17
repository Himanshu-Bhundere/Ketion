import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/block.dart' as domain;
import '../../domain/repositories/block_repository.dart';
import '../models/block_mapper.dart';

class BlockRepositoryImpl implements BlockRepository {
  final AppDatabase _db;
  final AppLogger _logger;

  BlockRepositoryImpl(this._db, this._logger);

  @override
  Future<Result<void>> createBlock(domain.Block block) async {
    try {
      await _db.into(_db.blocks).insert(block.toCompanion());
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to create block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<domain.Block>> getBlock(String id) async {
    try {
      final blockRecord = await (_db.select(_db.blocks)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (blockRecord == null) {
        return const Error(StorageFailure('Block not found'));
      }
      return Success(blockRecord.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateBlock(domain.Block block) async {
    try {
      final updatedRows = await (_db.update(_db.blocks)..where((t) => t.id.equals(block.id))).write(block.toCompanion());
      if (updatedRows == 0) {
        return const Error(StorageFailure('Block not found for update'));
      }
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to update block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteBlock(String id) async {
    try {
      final deletedRows = await (_db.delete(_db.blocks)..where((t) => t.id.equals(id))).go();
      if (deletedRows == 0) {
        return const Error(StorageFailure('Block not found for deletion'));
      }
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete block', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Block>>> getBlocksForPage(String pageId) async {
    try {
      final records = await (_db.select(_db.blocks)
            ..where((t) => t.pageId.equals(pageId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get blocks for page', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Block>>> getChildBlocks(String parentBlockId) async {
    try {
      final records = await (_db.select(_db.blocks)
            ..where((t) => t.parentBlockId.equals(parentBlockId))
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)]))
          .get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get child blocks', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
}
