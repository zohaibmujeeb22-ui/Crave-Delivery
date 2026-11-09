import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crave_delivery1/main.dart';

void main() {
  testWidgets('app loads the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CraveApp()));

    expect(find.text('Welcome to Crave'), findsOneWidget);
  });
}
