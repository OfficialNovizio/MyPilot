
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Working UI/app_controller.dart';
import '../models/shift.dart';
import '../services/ocr_service.dart';
import '../utils/shift_parse.dart';
import '../utils/time_utils.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _ocr = OcrService();
  bool _busy = false;
  String _raw = '';
  List<ShiftDraft> _drafts = [];
  String? _jobId;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    final c = Get.find<AppController>();
    _jobId = c.jobs.isNotEmpty ? c.jobs.first.id : null;
    _anchor = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  String _pad2(int n) => n < 10 ? '0$n' : '$n';

  Future<void> _runPick({bool camera = false}) async {
    if (_jobId == null) {
      Get.snackbar('No job', 'Please add at least one job first.');
      return;
    }
    setState(() { _busy = true; _raw = ''; _drafts = []; });
    try {
      final texts = await _ocr.pickAndExtractTexts(camera: camera);
      _raw = texts.join('\n');
      _drafts = parseShiftsText(_raw, anchorMonth: _anchor, defaultJobId: _jobId!);
    } catch (e) {
      Get.snackbar('OCR error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() { _busy = false; });
    }
  }

  void _save() {
    final c = Get.find<AppController>();
    for (final d in _drafts) {
      final s = Shift(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        jobId: d.jobId,
        date: d.date,
        start: d.start,
        end: d.end,
        breakMin: d.breakMin,
        notes: 'Imported',
      );
      c.addShift(s);
    }
    Get.back();
    Get.snackbar('Imported', '\${_drafts.length} shift(s) added.');
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Import from Photo')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _jobId,
                items: c.jobs.map((j) => DropdownMenuItem(
                  value: j.id, child: Text(j.name))).toList(),
                onChanged: (v) => setState(() => _jobId = v),
                decoration: const InputDecoration(labelText: 'Default job', isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '\${_anchor.year}-\${_pad2(_anchor.month)}-01',
                decoration: const InputDecoration(
                  labelText: 'Anchor month (YYYY-MM-01)', isDense: true),
                onChanged: (v) {
                  try {
                    final p = v.split('-');
                    setState(() => _anchor = DateTime(int.parse(p[0]), int.parse(p[1]), 1));
                  } catch (_) {}
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _runPick(camera: true),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Scan with camera'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _runPick(camera: false),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick from gallery'),
            ),
          ]),
          const SizedBox(height: 12),
          if (_busy) const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )),
          if (_raw.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text('Detected shifts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_drafts.isEmpty)
              const Text('No shift ranges found. Try a clearer photo or adjust Anchor month.',
                  style: TextStyle(color: Colors.grey))
            else
              ..._drafts.asMap().entries.map((e) => _DraftTile(
                draft: e.value,
                onChanged: (d) => setState(() => _drafts[e.key] = d),
                jobs: c.jobs.map((j) => MapEntry(j.id, j.name)).toList(),
              )),
            const SizedBox(height: 12),
            if (_drafts.isNotEmpty)
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_alt),
                label: Text('Import \${_drafts.length} shift(s)'),
              ),
          ],
        ],
      ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  final ShiftDraft draft;
  final void Function(ShiftDraft) onChanged;
  final List<MapEntry<String,String>> jobs;

  const _DraftTile({required this.draft, required this.onChanged, required this.jobs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF121315),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF232427)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: TextFormField(
                initialValue: draft.date,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', isDense: true),
                onChanged: (v) => onChanged(ShiftDraft(
                  date: v, start: draft.start, end: draft.end, jobId: draft.jobId, breakMin: draft.breakMin)),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                initialValue: draft.start,
                decoration: const InputDecoration(labelText: 'Start (HH:mm)', isDense: true),
                onChanged: (v) => onChanged(ShiftDraft(
                  date: draft.date, start: v, end: draft.end, jobId: draft.jobId, breakMin: draft.breakMin)),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                initialValue: draft.end,
                decoration: const InputDecoration(labelText: 'End (HH:mm)', isDense: true),
                onChanged: (v) => onChanged(ShiftDraft(
                  date: draft.date, start: draft.start, end: v, jobId: draft.jobId, breakMin: draft.breakMin)),
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: draft.jobId,
                  items: jobs.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => onChanged(ShiftDraft(
                    date: draft.date, start: draft.start, end: draft.end, jobId: v ?? draft.jobId, breakMin: draft.breakMin)),
                  decoration: const InputDecoration(labelText: 'Job', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextFormField(
                  initialValue: '\${draft.breakMin}',
                  decoration: const InputDecoration(labelText: 'Break (min)', isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onChanged(ShiftDraft(
                    date: draft.date, start: draft.start, end: draft.end, jobId: draft.jobId, breakMin: int.tryParse(v) ?? draft.breakMin)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
