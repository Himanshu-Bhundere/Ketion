import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/features/pages/domain/entities/page.dart';
import 'package:ketion/features/pages/presentation/providers/page_providers.dart';



final activePageIdProvider = StateProvider<String?>((ref) => null);
