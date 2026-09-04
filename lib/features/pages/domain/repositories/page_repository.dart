import '../../../../core/utils/result.dart';
import '../entities/page.dart';

abstract class PageRepository {
  Future<Result<void>> createPage(Page page);
  Future<Result<Page>> getPage(String id);
  Future<Result<void>> updatePage(Page page);
  Future<Result<void>> deletePage(String id);
  Future<Result<List<Page>>> getRecentPages();
  Future<Result<List<Page>>> getFavoritePages();
  Future<Result<List<Page>>> getChildPages(String parentId);
  Future<Result<List<Page>>> getTemplatePages();
}
