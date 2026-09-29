import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/editor/domain/models/block_data_models.dart';
import 'package:ketion/features/editor/domain/services/block_data_serializer.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  test('paragraph serialization round-trips through BlockDataModel', () {
    final encoded = BlockDataSerializer.encodeDocumentNode(
      ParagraphNode(id: 'paragraph', text: AttributedText('Hello world')),
    );

    final json = jsonDecode(encoded) as Map<String, dynamic>;
    expect(json['runtimeType'], 'text');
    expect(BlockDataModel.fromJson(json).searchableText, 'Hello world');
  });

  test('checklist serialization carries its type and searchable text', () {
    final encoded = BlockDataSerializer.encodeDocumentNode(
      TaskNode(id: 'task', text: AttributedText('Pack passport'), isComplete: false),
    );

    final json = jsonDecode(encoded) as Map<String, dynamic>;
    expect(json['runtimeType'], 'list');
    expect(json['listType'], 'checklist');
    expect(BlockDataModel.fromJson(json).searchableText, 'Pack passport');
  });
}
