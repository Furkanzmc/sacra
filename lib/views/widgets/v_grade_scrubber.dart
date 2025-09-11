import 'package:flutter/material.dart';

import '../../models/activity.dart';

class VGradeScrubber extends StatefulWidget {
  const VGradeScrubber({
    super.key,
    required this.onPicked,
    this.grades,
  });

  final void Function(Grade grade) onPicked;
  final List<String>? grades;

  @override
  State<VGradeScrubber> createState() => _VGradeScrubberState();
}

class _VGradeScrubberState extends State<VGradeScrubber> {
  int? _hoverIndex;

  List<String> get _grades => widget.grades ?? _defaultVGrades;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          onPanDown: (DragDownDetails d) => _updateFromDx(d.localPosition.dx, constraints.maxWidth),
          onPanUpdate: (DragUpdateDetails d) => _updateFromDx(d.localPosition.dx, constraints.maxWidth),
          onPanEnd: (_) => _commitPick(),
          onTapUp: (TapUpDetails d) => _commitFromDx(d.localPosition.dx, constraints.maxWidth),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: List<Widget>.generate(_grades.length, (int i) {
                final bool isActive = _hoverIndex == i;
                return Expanded(
                  child: Container(
                    color: isActive ? Colors.teal.withValues(alpha: 0.12) : null,
                    alignment: Alignment.center,
                    child: Text(
                      _grades[i],
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  void _updateFromDx(double dx, double width) {
    final int count = _grades.length;
    if (width <= 0 || count == 0) {
      return;
    }
    final double segment = width / count;
    int index = (dx / segment).floor();
    index = index.clamp(0, count - 1);
    setState(() => _hoverIndex = index);
  }

  void _commitPick() {
    final int? index = _hoverIndex;
    if (index == null) {
      return;
    }
    final String label = _grades[index];
    widget.onPicked(Grade(system: GradeSystem.vScale, value: label));
    setState(() => _hoverIndex = null);
  }

  void _commitFromDx(double dx, double width) {
    _updateFromDx(dx, width);
    _commitPick();
  }
}

const List<String> _defaultVGrades = <String>[
  'V0', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8',
  'V9', 'V10', 'V11', 'V12', 'V13', 'V14', 'V15', 'V16',
];


