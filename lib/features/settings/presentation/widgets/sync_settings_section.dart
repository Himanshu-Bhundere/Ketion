import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/auth/presentation/providers/auth_providers.dart';
import 'package:ketion/features/sync/presentation/providers/sync_providers.dart';
import 'package:ketion/core/utils/result.dart';

class SyncSettingsSection extends ConsumerWidget {
  const SyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Synchronization',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: const Text('Google Drive Sync'),
                subtitle: Text(_getStatusText(syncState.status)),
                trailing: _buildTrailing(context, ref, syncState),
              ),
              if (syncState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncState.errorMessage!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(SyncUiStatus status) {
    switch (status) {
      case SyncUiStatus.savedLocally:
        return 'Saved locally';
      case SyncUiStatus.syncPending:
        return 'Sync pending...';
      case SyncUiStatus.syncing:
        return 'Syncing...';
      case SyncUiStatus.synced:
        return 'Synced';
      case SyncUiStatus.offline:
        return 'Offline';
      case SyncUiStatus.syncFailed:
        return 'Sync failed';
      case SyncUiStatus.authenticationRequired:
        return 'Authentication required';
    }
  }

  Widget _buildTrailing(
      BuildContext context, WidgetRef ref, SyncUiState syncState) {
    if (syncState.status == SyncUiStatus.authenticationRequired) {
      return ElevatedButton(
        onPressed: () => _signIn(ref),
        child: const Text('Sign In'),
      );
    }

    if (syncState.status == SyncUiStatus.syncing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: () {
        ref.read(syncControllerProvider.notifier).syncNow();
      },
    );
  }

  Future<void> _signIn(WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService
        .signIn(['https://www.googleapis.com/auth/drive.file']);
    if (result is Success) {
      await ref
          .read(syncControllerProvider.notifier)
          .syncNow(); // Also re-initializes
    }
  }
}
