import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketion/core/router/app_router.dart';
import 'package:ketion/core/presentation/widgets/mobile_navigation.dart';
import 'package:ketion/core/presentation/widgets/tablet_workspace.dart';
import 'package:ketion/core/presentation/widgets/desktop_workspace.dart';

void main() {
  Widget buildTestApp(double width) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: appRouter,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: child!,
          );
        },
      ),
    );
  }

  testWidgets('AppShell renders MobileNavigation on compact screens', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestApp(400));
    await tester.pump(const Duration(milliseconds: 100));
    
    expect(find.byType(MobileNavigation), findsOneWidget);
    expect(find.byType(TabletWorkspace), findsNothing);
    expect(find.byType(DesktopWorkspace), findsNothing);
  });

  testWidgets('AppShell renders TabletWorkspace on medium screens', (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestApp(900));
    await tester.pump(const Duration(milliseconds: 100));
    
    expect(find.byType(MobileNavigation), findsNothing);
    expect(find.byType(TabletWorkspace), findsOneWidget);
    expect(find.byType(DesktopWorkspace), findsNothing);
  });

  testWidgets('AppShell renders DesktopWorkspace on expanded screens', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestApp(1200));
    await tester.pump(const Duration(milliseconds: 100));
    
    expect(find.byType(MobileNavigation), findsNothing);
    expect(find.byType(TabletWorkspace), findsNothing);
    expect(find.byType(DesktopWorkspace), findsOneWidget);
  });
}
