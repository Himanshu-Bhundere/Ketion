import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyNotifier extends AutoDisposeFamilyAsyncNotifier<String, String> {
  @override
  Future<String> build(String arg) async {
    return arg;
  }
}

final myProvider = AsyncNotifierProvider.autoDispose.family<MyNotifier, String, String>(
  MyNotifier.new,
);

void main() {}
