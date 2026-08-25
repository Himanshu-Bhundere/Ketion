import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/sync/domain/repositories/sync_engine_repository.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';

class SyncNowUseCase {
  final SyncEngineRepository repository;
  final WidgetService widgetService;

  SyncNowUseCase(this.repository, this.widgetService);

  Future<Result<void>> call() async {
    final result = await repository.syncNow();
    if (result is Success) {
      await widgetService.updateSimpleWidgetData('last_sync_time', DateTime.now().toIso8601String());
      await widgetService.updateSimpleWidgetData('sync_status', 'Success');
      await widgetService.triggerWidgetUpdate();
    } else {
      await widgetService.updateSimpleWidgetData('sync_status', 'Failed');
      await widgetService.triggerWidgetUpdate();
    }
    return result;
  }
}
