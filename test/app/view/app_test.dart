import 'package:flutter_test/flutter_test.dart';
import 'package:rent_system/features/auth/presentation/pages/landing_page.dart';
import '../../helpers/helpers.dart';

void main() {
  group('RentFlow UI', () {
    testWidgets('LandingPage shows welcome headline', (tester) async {
      await tester.pumpApp(const LandingPage());
      expect(find.text('Welcome to RentFlow'), findsOneWidget);
    });
  });
}
