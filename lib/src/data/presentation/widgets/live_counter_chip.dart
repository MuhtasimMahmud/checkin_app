import 'package:flutter/material.dart';

class LiveCounterChip extends StatelessWidget {
  final int count;
  const LiveCounterChip({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('Live: $count'));
  }
}
