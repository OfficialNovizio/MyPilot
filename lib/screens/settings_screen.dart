
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Working UI/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Obx(() => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: const Text('UI week starts on Monday'),
            subtitle: const Text('Affects the Week tab only'),
            value: c.settings.value.weekStartsOnMonday,
            onChanged: (v) => c.toggleWeekStart(v),
          ),
          SwitchListTile(
            title: const Text('Weekly overtime (1.5× per job)'),
            value: c.settings.value.overtimeEnabled,
            onChanged: (v) => c.settings.update((s) => s?.overtimeEnabled = v),
          ),
          ListTile(
            title: const Text('Overtime weekly threshold (hours)'),
            subtitle: Text('\${c.settings.value.overtimeThresholdWeekly}'),
            trailing: SizedBox(
              width: 120,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hours'),
                onChanged: (v) {
                  final x = int.tryParse(v) ?? c.settings.value.overtimeThresholdWeekly;
                  c.settings.update((s) { if (s == null) return; s.overtimeThresholdWeekly = x.clamp(0, 200); });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(title: const Text('Jump to This Week'), trailing: FilledButton(onPressed: c.thisWeek, child: const Text('Today'))),
        ],
      ),
    ));
  }
}
