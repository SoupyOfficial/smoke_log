import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log.dart';
import '../providers/log_providers.dart';
import '../providers/dropdown_options_provider.dart';
import '../models/reason_option.dart';

class AddLogForm extends ConsumerStatefulWidget {
  const AddLogForm({super.key});

  @override
  ConsumerState<AddLogForm> createState() => _AddLogFormState();
}

class _AddLogFormState extends ConsumerState<AddLogForm> {
  DateTime? _startTime;
  int _durationSeconds = 0;
  final _notesController = TextEditingController();
  List<String> _selectedReasons = [];
  int _moodRating = 7;
  int _physicalRating = 7;

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

      if (_durationSeconds > 0) {
        final log = Log(
          timestamp: DateTime.now(),
          durationSeconds: _durationSeconds,
          reason: _selectedReasons,
          moodRating: _moodRating,
          physicalRating: _physicalRating,
          potencyRating: 0,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        try {
          final logRepository = ref.read(logRepositoryProvider);
          await logRepository.addLog(log);
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
      _durationSeconds = 0;
      _notesController.clear();
      _selectedReasons = [];
      _moodRating = 7;
      _physicalRating = 7;
    });
  }

  Widget _buildDropdownOptions() {
    final optionsAsync = ref.watch(dropdownOptionsProvider);
    return optionsAsync.when(
      data: (options) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8.0,
            children: options.map((ReasonOption option) {
              final isSelected = _selectedReasons.contains(option.option);
              return ChoiceChip(
                label: Text(option.option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedReasons.add(option.option);
                    } else {
                      _selectedReasons.remove(option.option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
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
            // Use the Firestore options for the multi-select chips.
            _buildDropdownOptions(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mood: $_moodRating'),
                      Slider(
                        value: _moodRating.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_moodRating',
                        onChanged: (value) =>
                            setState(() => _moodRating = value.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Physical: $_physicalRating'),
                      Slider(
                        value: _physicalRating.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_physicalRating',
                        onChanged: (value) =>
                            setState(() => _physicalRating = value.toInt()),
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
