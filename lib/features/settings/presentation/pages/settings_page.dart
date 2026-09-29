import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ref.watch(appSettingsProvider).when(
            data: (settings) {
              return ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_medium),
                    title: const Text('Theme'),
                    trailing: DropdownButton<String>(
                      value: settings.themeMode,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateThemeMode(newValue);
                        }
                      },
                      items: <String>['System', 'Light', 'Dark']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Editor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.text_format),
                    title: Text('Default Typography'),
                    subtitle:
                        Text('Set standard text formatting for new notes'),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Storage & Cache',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services),
                    title: const Text('Clear Cache'),
                    subtitle: Text(
                      settings.lastCleanup != null
                          ? 'Last cleaned: ${settings.lastCleanup.toString().split('.')[0]}'
                          : 'Clear temporary files and image cache',
                    ),
                    onTap: () async {
                      await ref.read(appSettingsProvider.notifier).clearCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache cleared successfully'),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Data & Backup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Export Backup (ZIP)'),
                    subtitle:
                        const Text('Export database and attachments locally'),
                    onTap: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preparing backup...')),
                        );
                        await ref.read(backupServiceProvider).exportBackup();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Backup failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore Backup (ZIP)'),
                    subtitle: const Text(
                      'Restore database and attachments from a local file',
                    ),
                    onTap: () async {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select backup file...'),
                          ),
                        );
                        await ref.read(backupServiceProvider).restoreBackup();
                        if (context.mounted) {
                          await showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: const Text('Restore Successful'),
                              content: const Text(
                                'The backup has been restored. Please restart the app completely to load the restored database.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restore failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Google Drive Sync',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Sync Frequency'),
                    trailing: DropdownButton<String>(
                      value: settings.syncFrequency,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateSyncFrequency(newValue);
                        }
                      },
                      items: <String>[
                        'Manual',
                        '15 minutes',
                        '30 minutes',
                        '1 hour',
                        'Daily',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sync Now'),
                    subtitle: const Text('Manually trigger Google Drive sync'),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Syncing...')),
                      );
                      try {
                        await ref.read(syncNowUseCaseProvider)();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sync completed successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sync failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Accessibility',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.accessibility),
                    title: Text('High Contrast'),
                    subtitle: Text('Increase color contrast across the app'),
                    trailing: Switch(value: false, onChanged: null),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Diagnostics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const ListTile(
                    leading: Icon(Icons.bug_report),
                    title: Text('Export Debug Logs'),
                    subtitle:
                        Text('Save error and sync logs for troubleshooting'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading settings: $e')),
          ),
    );
  }
}
