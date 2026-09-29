import 'dart:io';

void fixFile(String path) {
  var content = File(path).readAsStringSync();
  
  if (!content.contains('pumpUntilInitialized')) {
    content = content.replaceFirst('void main() {', '''
Future<void> pumpUntilInitialized(WidgetTester tester) async {
  while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {''');
  }

  content = content.replaceAll(
    RegExp(r'await tester\.pumpAndSettle\(\);'),
    'await pumpUntilInitialized(tester);',
  );
  
  File(path).writeAsStringSync(content);
}

void main() {
  fixFile('test/features/editor/presentation/widgets/structural_mutation_integration_test.dart');
  fixFile('test/features/editor/presentation/widgets/super_editor_adapter_test.dart');
}
