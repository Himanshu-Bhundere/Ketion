import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';

class WidgetServiceWeb implements WidgetService {
  @override
  Future<Result<void>> updateSimpleWidgetData(String key, dynamic value) async {
    // No-op for web
    return const Success(null);
  }

  @override
  Future<Result<void>> triggerWidgetUpdate() async {
    // No-op for web
    return const Success(null);
  }

  @override
  Future<Result<void>> generateWidgetSnapshot() async {
    // No-op for web
    return const Success(null);
  }
}

WidgetService getWidgetService(dynamic db) => WidgetServiceWeb();
