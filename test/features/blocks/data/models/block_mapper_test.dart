import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/blocks/data/models/block_mapper.dart';
import 'package:ketion/features/blocks/domain/entities/block.dart';

Block _block(String data) => Block(
      id: 'block',
      pageId: 'page',
      type: 'text',
      position: 0,
      data: data,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  test('legacy editor JSON remains searchable', () {
    final companion = _block(
      '{"spans":[{"text":"Book hotel in Mumbai"}],"headingLevel":0}',
    ).toCompanion();

    expect(companion.searchableText.value, 'Book hotel in Mumbai');
  });

  test('canonical editor JSON populates searchable text', () {
    final companion = _block(
      '{"spans":[{"text":"Pack passport"}],"headingLevel":0,"runtimeType":"text"}',
    ).toCompanion();

    expect(companion.searchableText.value, 'Pack passport');
  });
}
