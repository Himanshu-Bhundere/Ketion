import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../media/presentation/providers/attachment_provider.dart';
import 'ketion_in_frame_player.dart';

class KetionVideoPlayerComponent extends ConsumerWidget {
  final String attachmentId;

  const KetionVideoPlayerComponent({
    super.key,
    required this.attachmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachmentId.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Invalid video block')),
      );
    }

    final attachmentAsync = ref.watch(attachmentProvider(attachmentId));

    return attachmentAsync.when(
      data: (attachment) {
        if (attachment == null) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('Video not found in database')),
          );
        }

        final pathAsync = ref.watch(attachmentPathProvider(attachment));

        return pathAsync.when(
          data: (localPath) {
            if (localPath == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Video file not available locally')),
              );
            }

            return KetionInFramePlayer(filePath: localPath);
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => SizedBox(
            height: 100,
            child: Center(child: Text('Error loading video path: $e')),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading video metadata: $e')),
      ),
    );
  }
}
