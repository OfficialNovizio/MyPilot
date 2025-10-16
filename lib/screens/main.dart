//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../services/storage_service.dart';
// import '../controllers/debt_controller.dart';
// import 'debt/debt_home.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await StorageService.init();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       theme: ThemeData.dark(useMaterial3: true),
//       home: const DebtShell(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class DebtShell extends StatefulWidget {
//   const DebtShell({super.key});
//   @override
//   State<DebtShell> createState() => _DebtShellState();
// }
//
// class _DebtShellState extends State<DebtShell> {
//   int _idx = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     Get.put(DebtController());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final tabs = [
//       const DebtHome(),
//       const DebtListScreen(),
//       const PlanScreen(),
//       const DebtSettingsScreen(),
//     ];
//     final items = const [
//       BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
//       BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Debts'),
//       BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), label: 'Plan'),
//       BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
//     ];
//     return Scaffold(
//       appBar: AppBar(title: const Text('Debt Manager')),
//       body: tabs[_idx],
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _idx,
//         destinations: [for (final i in items) NavigationDestination(icon: i.icon!, label: i.label!)],
//         onDestinationSelected: (i)=>setState(()=>_idx=i),
//       ),
//     );
//   }
// }
