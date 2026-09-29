import '../../../../core/utils/result.dart';
import '../../../editor/domain/models/drop_intent.dart';
import '../entities/block.dart';

abstract class BlockRepository {
  Future<Result<void>> createBlock(Block block);
  Future<Result<Block>> getBlock(String id);
  Future<Result<void>> updateBlock(Block block, {required int expectedVersion});
  Future<Result<void>> deleteBlock(String id, {required int expectedVersion});
  Future<Result<List<Block>>> getBlocksForPage(String pageId);
  Future<Result<List<Block>>> getChildBlocks(String parentBlockId);
  Future<Result<List<Block>>> moveBlock(String sourceBlockId, DropIntent intent); // Wait, moveBlock in gateway doesn't use DropIntent anymore. Gateway uses moveBlock directly? 
  // Ah, the gateway currently uses updateBlock for MoveBlockMutation!

  Future<Result<void>> splitBlock({
    required Block updatedOriginalBlock,
    required int originalExpectedVersion,
    required Block newBlock,
  });
  Future<Result<void>> mergeBlocks({
    required Block mergedBlock,
    required int survivorExpectedVersion,
    required String deletedBlockId,
    required int victimExpectedVersion,
  });
  Future<Result<void>> restoreBlock(String id, String data, String? parentBlockId, double position);
}
