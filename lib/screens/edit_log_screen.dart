import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log.dart';
import '../models/reason_option.dart';
import '../providers/dropdown_options_provider.dart';
import '../services/log_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/format_utils.dart';

class EditLogScreen extends ConsumerStatefulWidget {
  final Log log;

  const EditLogScreen({super.key, required this.log});

  @override
  ConsumerState<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends ConsumerState<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late double _durationSeconds;
  late int _moodRating;
  late int _physicalRating;
  late int _potencyRating;
  late List<String> _selectedReasons;

  // Keep timestamp for reference but don't allow editing
  late DateTime _timestamp;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.log.notes ?? '');
    _durationSeconds = widget.log.durationSeconds;
    _moodRating = widget.log.moodRating;
    _physicalRating = widget.log.physicalRating;
    _potencyRating = widget.log.potencyRating ?? 0;
    _timestamp = widget.log.timestamp;
    _selectedReasons = widget.log.reason?.toList() ?? [];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateLog() async {
    if (_formKey.currentState!.validate()) {
      // Create updated log with all fields
      final updatedLog = widget.log.copyWith(
        notes: _notesController.text,
        reason: _selectedReasons,
        durationSeconds: _durationSeconds,
        moodRating: _moodRating,
        physicalRating: _physicalRating,
        potencyRating: _potencyRating,
        // Keep the original timestamp
        timestamp: widget.log.timestamp,
      );

      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final repository = LogRepository(userId);
        await repository.updateLog(updatedLog);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating log: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildReasonChips() {
    final optionsAsync = ref.watch(dropdownOptionsProvider);
    return optionsAsync.when(
      data: (options) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
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
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display timestamp (non-editable)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Timestamp: ${_timestamp.toLocal().toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Duration field
              TextFormField(
                initialValue: formatSecondsDisplay(_durationSeconds),
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) {
                  double? parsed = double.tryParse(value);
                  if (parsed != null) {
                    _durationSeconds = parsed; // Store full precision
                  }
                },
              ),
              const SizedBox(height: 16),

              // Replace text field with chips
              _buildReasonChips(),

              const SizedBox(height: 16),

              // Mood rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Mood rating: $_moodRating'), // Remove toStringAsFixed(1)
                  Slider(
                    value: _moodRating.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _moodRating = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Physical rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Physical rating: $_physicalRating'), // Remove toStringAsFixed(1)
                  Slider(
                    value: _physicalRating.toDouble(),
                    min: 0.0,
                    max: 10.0,
                    divisions:
                        10, // Changed from 20 to make it consistent with integers 0-10
                    onChanged: (value) {
                      setState(() {
                        _physicalRating = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Potency rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Potency rating: $_potencyRating'),
                  Slider(
                    value: _potencyRating.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        _potencyRating = value.round();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save and Cancel buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateLog,
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
