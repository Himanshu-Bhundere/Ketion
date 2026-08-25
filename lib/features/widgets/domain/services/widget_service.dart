import 'package:ketion/core/utils/result.dart';

abstract class WidgetService {
  /// Updates lightweight widget data (e.g. Sync Status, Quick Note details) in SharedPreferences.
  Future<Result<void>> updateSimpleWidgetData(String key, dynamic value);

  /// Triggers a native widget update broadcast to refresh all Android widgets.
  Future<Result<void>> triggerWidgetUpdate();

  /// Creates a read-only snapshot DB of recent notes for complex widgets to read.
  Future<Result<void>> generateWidgetSnapshot();
}
