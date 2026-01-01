// import 'package:get/get.dart';
// import '../services/storage_service.dart';
// import '../models/debt.dart';
//
// class DebtController extends GetxController {
//   static const _kDebts = 'debts_v1';
//   final debts = <DebtAccount>[].obs;
//
//   // UI & settings
//   final monthlyBudget = 300.0.obs;
//   final strategy = Strategy.snowball.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     final list = StorageService.read<List>(_kDebts);
//     if (list != null) {
//       debts.assignAll(list.map((e) => DebtAccount.fromJson(Map<String,dynamic>.from(e))).toList());
//     }
//   }
//
//   void save() {
//     StorageService.write(_kDebts, debts.map((e)=>e.toJson()).toList());
//   }
//
//   void addOrUpdate(DebtAccount d) {
//     final i = debts.indexWhere((x)=>x.id==d.id);
//     if (i>=0) debts[i]=d; else debts.add(d);
//     save();
//   }
//
//   void remove(String id) {
//     debts.removeWhere((e)=>e.id==id);
//     save();
//   }
//
//   PlanSummary computePlan() {
//     return buildPlan(
//       debts: debts.toList(),
//       monthlyBudget: monthlyBudget.value,
//       strategy: strategy.value,
//     );
//   }
// }
