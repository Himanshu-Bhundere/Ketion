import 'dart:io';

void fixFile(String path) {
  var content = File(path).readAsStringSync();
  content = content.replaceFirst(
'''Future<void> pumpUntilInitialized(WidgetTester tester) async {
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}''',
'''Future<void> pumpUntilInitialized(WidgetTester tester) async {
  int attempts = 0;
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty && attempts < 50) {
    await tester.pump(const Duration(milliseconds: 50));
    attempts++;
  }
  if (attempts >= 50) {
    throw Exception('pumpUntilInitialized timed out waiting for CircularProgressIndicator to disappear');
  }
  await tester.pump(const Duration(milliseconds: 50));
}'''
  );
  File(path).writeAsStringSync(content);
}

void main() {
  fixFile('test/features/editor/presentation/widgets/structural_mutation_integration_test.dart');
  fixFile('test/features/editor/presentation/widgets/super_editor_adapter_test.dart');
}
