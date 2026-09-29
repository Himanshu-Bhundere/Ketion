import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

class TestImageNode {
  void test() {
    ImageNode node = ImageNode(id: '1', imageUrl: 'test');
    debugPrint(node.toString());
  }
}
