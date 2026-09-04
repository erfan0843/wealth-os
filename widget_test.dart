import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wealth_os/app/app_root.dart';

void main() {
  testWidgets('app root builds the dashboard shell with Persian labels',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AppRoot()));
    await tester.pump();
    expect(find.text('دارایی خالص'), findsOneWidget);
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('دارایی‌ها'), findsOneWidget);
  });
}
