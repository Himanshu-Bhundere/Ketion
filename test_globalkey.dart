import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class OldWidget extends StatefulWidget {
  const OldWidget({super.key});
  @override
  State<OldWidget> createState() => _OldWidgetState();
}
class _OldWidgetState extends State<OldWidget> {
  final _childKey = GlobalKey();
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text('Old', key: _childKey, textDirection: TextDirection.ltr))]);
}

class NewWidget extends StatefulWidget {
  const NewWidget({super.key});
  @override
  State<NewWidget> createState() => _NewWidgetState();
}
class _NewWidgetState extends State<NewWidget> {
  final _childKey = GlobalKey();
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text('New', key: _childKey, textDirection: TextDirection.ltr))]);
}

void main() {
  testWidgets('GlobalKey type change with nested global keys', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(OldWidget(key: key));
    await tester.pumpWidget(NewWidget(key: key));
  });
}
