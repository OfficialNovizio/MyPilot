import 'package:emptyproject/Working%20UI/Account/Account%20Getx.dart';
import 'package:emptyproject/Working%20UI/Dashboard/Dashboard%20Getx.dart';
import 'package:emptyproject/Working%20UI/Shift/Shift%20Getx.dart';
import 'package:emptyproject/Working%20UI/app_controller.dart';
import 'package:get/get.dart';

final DashboardController home = Get.put(DashboardController());
// final ShiftScreenController shift = Get.put(ShiftScreenController());
final ShiftController shift = Get.put(ShiftController());
final AccountController account = Get.put(AccountController());
final AppController app = Get.put(AppController());
