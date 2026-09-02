import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tag.dart' as domain;
import '../../domain/repositories/tag_repository.dart';
import '../models/tag_mapper.dart';

class TagRepositoryImpl implements TagRepository {
  final AppDatabase _db;
  final AppLogger _logger;

  TagRepositoryImpl(this._db, this._logger);

  @override
  Future<Result<void>> createTag(domain.Tag tag) async {
    try {
      await _db.into(_db.tags).insert(tag.toCompanion());
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to create tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<domain.Tag>> getTag(String id) async {
    try {
      final tagRecord = await (_db.select(_db.tags)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (tagRecord == null) {
        return const Error(StorageFailure('Tag not found'));
      }
      return Success(tagRecord.toDomain());
    } catch (e, stackTrace) {
      _logger.e('Failed to get tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateTag(domain.Tag tag) async {
    try {
      final updatedRows = await (_db.update(_db.tags)
            ..where((t) => t.id.equals(tag.id)))
          .write(tag.toCompanion());
      if (updatedRows == 0) {
        return const Error(StorageFailure('Tag not found for update'));
      }
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to update tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTag(String id) async {
    try {
      final deletedRows =
          await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
      if (deletedRows == 0) {
        return const Error(StorageFailure('Tag not found for deletion'));
      }
      return const Success(null);
    } catch (e, stackTrace) {
      _logger.e('Failed to delete tag', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<domain.Tag>>> getAllTags() async {
    try {
      final records = await (_db.select(_db.tags)).get();
      return Success(records.map((r) => r.toDomain()).toList());
    } catch (e, stackTrace) {
      _logger.e('Failed to get all tags', e, stackTrace);
      return Error(StorageFailure(e.toString()));
    }
  }
}
