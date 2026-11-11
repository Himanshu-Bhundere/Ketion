// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) {
    print('[patch_super_editor] Warning: .dart_tool/package_config.json not found.');
    return;
  }

  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final superEditorPkg = packages.firstWhere(
    (p) => p['name'] == 'super_editor',
    orElse: () => null,
  );

  if (superEditorPkg == null) {
    print('[patch_super_editor] super_editor not found in package_config.json.');
    return;
  }

  var rootUriStr = superEditorPkg['rootUri'] as String;
  if (!rootUriStr.endsWith('/')) {
    rootUriStr = '$rootUriStr/';
  }
  final rootUri = Uri.parse(rootUriStr);
  final targetPath = File.fromUri(
    rootUri.resolve('lib/src/default_editor/document_ime/ime_decoration.dart'),
  );

  if (!targetPath.existsSync()) {
    print('[patch_super_editor] Warning: ime_decoration.dart not found at ${targetPath.path}');
    return;
  }

  final content = targetPath.readAsStringSync();
  const badMethod =
      'void updateStyle(TextInputStyle style) => client?.updateStyle(style);';
  const badOverride =
      '@override\n  void updateStyle(TextInputStyle style) => client?.updateStyle(style);';

  if (content.contains('// void updateStyle(TextInputStyle style)')) {
    print('[patch_super_editor] super_editor ime_decoration.dart is already patched.');
    return;
  }

  if (content.contains(badMethod)) {
    final patched = content
        .replaceAll(
          badOverride,
          '// @override\n  // void updateStyle(TextInputStyle style) => client?.updateStyle(style);',
        )
        .replaceAll(
          badMethod,
          '// void updateStyle(TextInputStyle style) => client?.updateStyle(style);',
        );
    targetPath.writeAsStringSync(patched);
    print('[patch_super_editor] Successfully patched super_editor ime_decoration.dart');
  } else {
    print('[patch_super_editor] No patch needed: updateStyle not present.');
  }
}
