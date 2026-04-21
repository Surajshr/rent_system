import 'package:rent_system/app/rent_flow_app.dart';
import 'package:rent_system/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const RentFlowApp());
}
