import 'package:flutter/material.dart';
import '../models/log.dart';
import '../services/log_repository.dart';

class AddLogForm extends StatefulWidget {
  final LogRepository logRepository;

  const AddLogForm({
    super.key,
    required this.logRepository,
  });

  @override
  State<AddLogForm> createState() => _AddLogFormState();
}

class _AddLogFormState extends State<AddLogForm> {
  DateTime? _startTime;
  int _durationSeconds = 0;
  final _notesController = TextEditingController();
  String _selectedReason = '';
  double _moodRating = 3.0;
  double _physicalRating = 3.0;

  final List<String> _reasons = [
    'Stress Relief',
    'Social',
    'Relaxation',
    'Habit',
    'Other'
  ];

  void _startTimer() {
    setState(() {
      _startTime = DateTime.now();
      _durationSeconds = 0;
    });
  }

  void _stopTimerAndSave() async {
    if (_startTime != null) {
      setState(() {
        _durationSeconds = DateTime.now().difference(_startTime!).inSeconds;
        _startTime = null;
      });

      // Only save if duration is greater than 0 seconds
      if (_durationSeconds > 0) {
        final log = Log(
          timestamp: DateTime.now(),
          durationSeconds: _durationSeconds,
          reason: _selectedReason.isEmpty ? 'Other' : _selectedReason,
          moodRating: _moodRating,
          physicalRating: _physicalRating,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        try {
          await widget.logRepository.addLog(log);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log added successfully')),
            );
            _resetForm();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add log')),
            );
          }
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _startTime = null;
      _durationSeconds = 0;
      _notesController.clear();
      _selectedReason = '';
      _moodRating = 3.0;
      _physicalRating = 3.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hold to Track',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_startTime != null)
              Text(
                'Duration: ${_durationSeconds}s',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onLongPressStart: (_) => _startTimer(),
              onLongPressEnd: (_) => _stopTimerAndSave(),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _startTime != null ? Colors.red : Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _startTime != null ? Icons.stop : Icons.touch_app,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _startTime != null
                  ? 'Release to save'
                  : 'Press and hold to start tracking',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              value: _selectedReason.isEmpty ? null : _selectedReason,
              items: _reasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedReason = value ?? ''),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mood: ${_moodRating.toStringAsFixed(1)}'),
                      Slider(
                        value: _moodRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: _moodRating.toStringAsFixed(1),
                        onChanged: (value) =>
                            setState(() => _moodRating = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Physical: ${_physicalRating.toStringAsFixed(1)}'),
                      Slider(
                        value: _physicalRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: _physicalRating.toStringAsFixed(1),
                        onChanged: (value) =>
                            setState(() => _physicalRating = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
