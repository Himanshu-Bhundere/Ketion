import '../../../../core/utils/result.dart';
import '../entities/collection.dart';

abstract class CollectionRepository {
  Future<Result<void>> createCollection(Collection collection);
  Future<Result<Collection>> getCollection(String id);
  Future<Result<void>> updateCollection(Collection collection);
  Future<Result<void>> deleteCollection(String id);
  Future<Result<List<Collection>>> getAllCollections();
  Future<Result<List<Collection>>> getCollectionsForPage(String pageId);
  Future<Result<void>> assignCollectionToPage(
      String pageId, String collectionId,);
  Future<Result<void>> removeCollectionFromPage(
      String pageId, String collectionId,);
  Future<Result<void>> setPageCollections(
      String pageId, List<String> collectionIds,);
}
