import 'package:get/get.dart';

class NavController extends GetxController {
  var selectedIndex = 0.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  void updateIndexBasedOnRoute(String route) {
    switch (route) {
      case '/':
        selectedIndex.value = 0;
        break;
      case '/playlist':
        selectedIndex.value = 1;
        break;
      case '/profile':
        selectedIndex.value = 2;
        break;
      default:
        selectedIndex.value = 0;
    }
  }
}
