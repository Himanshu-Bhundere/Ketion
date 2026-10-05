import '../../../../core/utils/result.dart';
import '../entities/tag.dart';

abstract class TagRepository {
  Future<Result<void>> createTag(Tag tag);
  Future<Result<Tag>> getTag(String id);
  Future<Result<void>> updateTag(Tag tag);
  Future<Result<void>> deleteTag(String id);
  Future<Result<List<Tag>>> getAllTags();
  Future<Result<List<Tag>>> getTagsForPage(String pageId);
  Future<Result<void>> assignTagToPage(String pageId, String tagId);
  Future<Result<void>> removeTagFromPage(String pageId, String tagId);
  Future<Result<void>> setPageTags(String pageId, List<String> tagIds);
}
