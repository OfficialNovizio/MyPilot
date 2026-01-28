import 'package:emptyproject/Working%20UI/Account/Account.dart';
import 'package:emptyproject/Working%20UI/Shift/Shift%20Screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Debts/Debt and Expense Tab.dart';
import '../Priotizer/Priotizer Screen.dart';

enum ScreenEnums {
  shifts,
  debts,
  prioritizer,
  account,
}

class DashboardController extends GetxController {
  RxString? activeIcon = "Shifts".obs;
  Rx<Widget>? currentScreen = Rx<Widget>(ShiftBody());
  RxList<Map> bottomIcons = RxList<Map>([
    {
      "Route": ScreenEnums.shifts,
      "Title": "Shifts",
    },
    {
      "Route": ScreenEnums.debts,
      "Title": "Debts",
    },
    {
      "Route": ScreenEnums.prioritizer,
      "Title": "Prioritizer",
    },
    {
      "Route": ScreenEnums.account,
      "Title": "Account",
    },
  ]);

  void changeCurrentScreen(ScreenEnums screen) {
    switch (screen) {
      case ScreenEnums.shifts:
        activeIcon!.value = 'Shifts';
        currentScreen!.value = ShiftBody();
        break;
      case ScreenEnums.debts:
        activeIcon!.value = 'Debts';
        currentScreen!.value = DebtBody();
        break;
      case ScreenEnums.prioritizer:
        activeIcon!.value = 'Prioritizer';
        currentScreen!.value = PrioritizerBody();
        break;
      case ScreenEnums.account:
        activeIcon!.value = 'Account';
        currentScreen!.value = AccountScreen();
        break;
    }
    activeIcon!.refresh();
  }
}
