import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';

class UpdateWidgetsUseCase {
  final WidgetService _widgetService;

  UpdateWidgetsUseCase(this._widgetService);

  Future<Result<void>> call() async {
    // We update the recent pages snapshot
    final snapshotResult = await _widgetService.generateWidgetSnapshot();
    if (snapshotResult is Error) {
      return snapshotResult;
    }

    // Trigger update on the native side
    return await _widgetService.triggerWidgetUpdate();
  }
}
