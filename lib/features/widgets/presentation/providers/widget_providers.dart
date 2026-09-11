import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/widgets/data/services/widget_service_factory.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:ketion/features/widgets/domain/usecases/update_widgets_usecase.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return getWidgetService(db);
});

final updateWidgetsUseCaseProvider = Provider<UpdateWidgetsUseCase>((ref) {
  final service = ref.watch(widgetServiceProvider);
  return UpdateWidgetsUseCase(service);
});
