import '../../../../core/utils/result.dart';
import '../entities/block.dart';

abstract class BlockRepository {
  Future<Result<void>> createBlock(Block block);
  Future<Result<Block>> getBlock(String id);
  Future<Result<void>> updateBlock(Block block);
  Future<Result<void>> deleteBlock(String id);
  Future<Result<List<Block>>> getBlocksForPage(String pageId);
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId);
}
