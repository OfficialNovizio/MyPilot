import 'package:emptyproject/Working%20UI/Account/Account%20Getx.dart';
import 'package:emptyproject/Working%20UI/Dashboard/Dashboard%20Getx.dart';
import 'package:emptyproject/Working%20UI/Shift/Shift%20Getx.dart';
import 'package:emptyproject/Working%20UI/app_controller.dart';
import 'package:get/get.dart';

import '../controllers/debt_controller.dart';
import 'Deposit/Debt Getx.dart';
import 'Priotizer/Priotizer Getx.dart';
import 'Shift/Deposits/Deposit Getx.dart';
import 'Shift/Overview/OverviewGetx.dart';
import 'Shift/Projection/Projection Getx.dart';

final DashboardController home = Get.put(DashboardController());
final ProitizerGetx priotizer = Get.put(ProitizerGetx());
final ShiftController shift = Get.put(ShiftController());
final AccountController account = Get.put(AccountController());
final AppController app = Get.put(AppController());
final OverviewInsightsController overview = Get.put(OverviewInsightsController());
final DepositsController deposit = Get.put(DepositsController());
final ProjectionController projection = Get.put(ProjectionController());
final DebtController debt = Get.put(DebtController());
