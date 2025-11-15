import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/activity.dart';

class VGradePopupScrubber extends StatefulWidget {
  const VGradePopupScrubber({
    super.key,
    required this.onPicked,
    this.grades,
    this.trailing,
  });

  final void Function(Grade grade) onPicked;
  final List<String>? grades;
  final Widget? trailing;

  @override
  State<VGradePopupScrubber> createState() => _VGradePopupScrubberState();
}

class _VGradePopupScrubberState extends State<VGradePopupScrubber> {
  // Track selections to promote shortcuts after repeated picks
  final Map<String, int> _counts = <String, int>{};
  final List<String> _shortcuts = <String>[];

  List<String> get _grades => widget.grades ?? _defaultVGrades;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _grades
                          .map((String g) => Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 8),
                                child: _Segment(
                                  label: g,
                                  onPressed: () => _onPick(g),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                if (widget.trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],
              ],
            ),
            if (_shortcuts.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _shortcuts
                      .map((String g) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Segment(
                              label: g,
                              onPressed: () => _onPick(g),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onPick(String label) {
    final int next = (_counts[label] ?? 0) + 1;
    _counts[label] = next;
    if (next >= 2 && !_shortcuts.contains(label)) {
      setState(() {
        _shortcuts.add(label);
      });
    }
    widget.onPicked(Grade(system: GradeSystem.vScale, value: label));
  }
}

class YdsGradePopupScrubber extends StatefulWidget {
  const YdsGradePopupScrubber({
    super.key,
    required this.onPicked,
    this.grades,
    this.trailing,
  });

  final void Function(Grade grade) onPicked;
  final List<String>? grades;
  final Widget? trailing;

  @override
  State<YdsGradePopupScrubber> createState() => _YdsGradePopupScrubberState();
}

class _YdsGradePopupScrubberState extends State<YdsGradePopupScrubber> {
  final Map<String, int> _counts = <String, int>{};
  final List<String> _shortcuts = <String>[];

  List<String> get _grades => widget.grades ?? _defaultYdsGrades;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _grades
                          .map((String g) => Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 8),
                                child: _Segment(
                                  label: g,
                                  onPressed: () => _onPick(g),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                if (widget.trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],
              ],
            ),
            if (_shortcuts.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _shortcuts
                      .map((String g) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Segment(
                              label: g,
                              onPressed: () => _onPick(g),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onPick(String label) {
    final int next = (_counts[label] ?? 0) + 1;
    _counts[label] = next;
    if (next >= 2 && !_shortcuts.contains(label)) {
      setState(() {
        _shortcuts.add(label);
      });
    }
    widget.onPicked(Grade(system: GradeSystem.yds, value: label));
  }
}

const List<String> _defaultYdsGrades = <String>[
  '5.4', '5.5', '5.6', '5.7', '5.8', '5.9',
  '5.10a', '5.10b', '5.10c', '5.10d',
  '5.11a', '5.11b', '5.11c', '5.11d',
  '5.12a', '5.12b', '5.12c', '5.12d',
  '5.13a', '5.13b', '5.13c', '5.13d',
  '5.14a', '5.14b', '5.14c', '5.14d',
  '5.15a', '5.15b', '5.15c', '5.15d',
];

const List<String> _defaultVGrades = <String>[
  'V0', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8',
  'V9', 'V10', 'V11', 'V12', 'V13', 'V14', 'V15', 'V16',
];

// Popup removed; using horizontal scrollers instead

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label),
        ),
      );
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}


