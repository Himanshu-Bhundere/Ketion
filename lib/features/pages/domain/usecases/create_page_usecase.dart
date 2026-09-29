import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import 'package:ketion/features/widgets/domain/usecases/update_widgets_usecase.dart';
import '../entities/page.dart';
import '../repositories/page_repository.dart';

class CreatePageUseCase {
  final PageRepository _repository;
  final UpdateWidgetsUseCase _updateWidgetsUseCase;
  final Uuid _uuid;

  CreatePageUseCase(this._repository, this._updateWidgetsUseCase, [Uuid? uuid])
      : _uuid = uuid ?? const Uuid();

  Future<Result<Page>> call({
    required String title,
    String? parentPageId,
    String? icon,
    String? coverImage,
    bool isTemplate = false,
  }) async {
    final now = DateTime.now();
    final page = Page(
      id: _uuid.v7(),
      parentPageId: parentPageId,
      title: title,
      icon: icon,
      coverImage: coverImage,
      isTemplate: isTemplate,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createPage(page);
    if (result is Success) {
      unawaited(
        _updateWidgetsUseCase().catchError((Object e, StackTrace s) {
          debugPrint('Widget refresh failed: $e');
          return const Success<void>(null);
        }),
      );
    }
    return result.fold(
      (_) => Success(page),
      (Failure failure) => Error(failure),
    );
  }
}
