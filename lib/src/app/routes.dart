import 'package:checkin_app/src/data/presentation/pages/home_page.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const home = '/';
}

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.home, page: () => const HomePage()),
  ];
}
