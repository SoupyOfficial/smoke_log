import 'package:flutter/material.dart';

class RatingSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final Color? activeColor;
  final ValueChanged<int> onChanged;

  const RatingSlider({
    Key? key,
    required this.label,
    required this.value,
    this.min = 1,
    this.max = 10,
    this.divisions = 9,
    this.activeColor,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            '$label: $value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            label: '$value',
            activeColor: activeColor ?? Theme.of(context).primaryColor,
            onChanged: (newValue) => onChanged(newValue.toInt()),
          ),
        ),
      ],
    );
  }
}
