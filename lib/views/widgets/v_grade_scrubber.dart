import 'dart:math' as math;
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
  OverlayEntry? _entry;
  ValueNotifier<int>? _indexNotifier;
  double? _popupTop;
  // ignore: unused_field
  double? _popupLeft; // reserved for future horizontal placement tweaks
  static const double _itemHeight = 36;
  static const double _popupWidth = 140;

  List<String> get _grades => widget.grades ?? _defaultVGrades;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final List<String> quick = <String>['V1', 'V2', 'V3', 'V4'];
        return Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ...quick.map((String g) => _Segment(
                        label: g,
                        onPressed: () => _onQuickPick(g),
                      )),
                  GestureDetector(
                    onTapDown: (TapDownDetails d) {
                      _showOverlay(context, d.globalPosition);
                      _updateFromGlobal(d.globalPosition);
                    },
                    onPanStart: (DragStartDetails d) => _updateFromGlobal(d.globalPosition),
                    onPanUpdate: (DragUpdateDetails d) => _updateFromGlobal(d.globalPosition),
                    onTapUp: (_) => _commitPick(),
                    onPanEnd: (_) => _commitPick(),
                    child: _Segment(
                      label: 'More',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            if (widget.trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        );
      },
    );
  }

  void _onQuickPick(String label) {
    widget.onPicked(Grade(system: GradeSystem.vScale, value: label));
  }

  

  void _showOverlay(BuildContext context, Offset globalPos) {
    final OverlayState overlay = Overlay.of(context);

    // Compute popup placement near the press position.
    final Size screen = MediaQuery.of(context).size;
    final double totalHeight = _itemHeight * _grades.length;
    final double margin = 12;
    final double top = math.max(
      margin,
      math.min(globalPos.dy - (_itemHeight * 4), screen.height - totalHeight - margin),
    );
    final double left = math.max(
      margin,
      math.min(globalPos.dx - (_popupWidth / 2), screen.width - _popupWidth - margin),
    );

    _popupTop = top;
    _popupLeft = left;
    final ValueNotifier<int> indexNotifier = ValueNotifier<int>(0);
    _indexNotifier = indexNotifier;

    final double popupTop = top;
    final double popupLeft = left;

    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return _GradePopup(
          top: popupTop,
          left: popupLeft,
          width: _popupWidth,
          itemHeight: _itemHeight,
          grades: _grades,
          indexListenable: indexNotifier,
          onCancel: _removeOverlay,
          onCommit: (int index) {
            final String label = _grades[index];
            widget.onPicked(Grade(system: GradeSystem.vScale, value: label));
            _removeOverlay();
          },
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    _indexNotifier?.dispose();
    _indexNotifier = null;
    _popupTop = null;
    _popupLeft = null;
  }

  void _updateFromGlobal(Offset global) {
    if (_popupTop == null || _indexNotifier == null) {
      return;
    }
    final double dy = global.dy - _popupTop!;
    int index = (dy / _itemHeight).floor();
    index = index.clamp(0, _grades.length - 1);
    if (_indexNotifier!.value != index) {
      _indexNotifier!.value = index;
      _entry?.markNeedsBuild();
    }
  }

  void _commitPick() {
    if (_indexNotifier == null) {
      return;
    }
    final int index = _indexNotifier!.value;
    final String label = _grades[index];
    widget.onPicked(Grade(system: GradeSystem.vScale, value: label));
    _removeOverlay();
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
  OverlayEntry? _entry;
  ValueNotifier<int>? _indexNotifier;
  double? _popupTop;
  // ignore: unused_field
  double? _popupLeft; // reserved for future horizontal placement tweaks
  static const double _itemHeight = 36;
  static const double _popupWidth = 160;

  List<String> get _grades => widget.grades ?? _defaultYdsGrades;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final List<String> quick = <String>['5.8', '5.9', '5.10a', '5.11a'];
        return Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ...quick.map((String g) => _Segment(
                        label: g,
                        onPressed: () => _onQuickPick(g),
                      )),
                  GestureDetector(
                    onTapDown: (TapDownDetails d) {
                      _showOverlay(context, d.globalPosition);
                      _updateFromGlobal(d.globalPosition);
                    },
                    onPanStart: (DragStartDetails d) => _updateFromGlobal(d.globalPosition),
                    onPanUpdate: (DragUpdateDetails d) => _updateFromGlobal(d.globalPosition),
                    onTapUp: (_) => _commitPick(),
                    onPanEnd: (_) => _commitPick(),
                    child: _Segment(
                      label: 'More',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            if (widget.trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        );
      },
    );
  }

  void _onQuickPick(String label) {
    widget.onPicked(Grade(system: GradeSystem.yds, value: label));
  }

  void _showOverlay(BuildContext context, Offset globalPos) {
    final OverlayState overlay = Overlay.of(context);
    final Size screen = MediaQuery.of(context).size;
    final double totalHeight = _itemHeight * _grades.length;
    final double margin = 12;
    final double top = math.max(
      margin,
      math.min(globalPos.dy - (_itemHeight * 4), screen.height - totalHeight - margin),
    );
    final double left = math.max(
      margin,
      math.min(globalPos.dx - (_popupWidth / 2), screen.width - _popupWidth - margin),
    );
    _popupTop = top;
    _popupLeft = left;
    final ValueNotifier<int> indexNotifier = ValueNotifier<int>(0);
    _indexNotifier = indexNotifier;
    final double popupTop = top;
    final double popupLeft = left;

    _entry = OverlayEntry(
      builder: (BuildContext context) {
        return _GradePopup(
          top: popupTop,
          left: popupLeft,
          width: _popupWidth,
          itemHeight: _itemHeight,
          grades: _grades,
          indexListenable: indexNotifier,
          onCancel: _removeOverlay,
          onCommit: (int index) {
            final String label = _grades[index];
            widget.onPicked(Grade(system: GradeSystem.yds, value: label));
            _removeOverlay();
          },
        );
      },
    );
    overlay.insert(_entry!);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    _indexNotifier?.dispose();
    _indexNotifier = null;
    _popupTop = null;
    _popupLeft = null;
  }

  void _updateFromGlobal(Offset global) {
    if (_popupTop == null || _indexNotifier == null) {
      return;
    }
    final double dy = global.dy - _popupTop!;
    int index = (dy / _itemHeight).floor();
    index = index.clamp(0, _grades.length - 1);
    if (_indexNotifier!.value != index) {
      _indexNotifier!.value = index;
      _entry?.markNeedsBuild();
    }
  }

  void _commitPick() {
    if (_indexNotifier == null) {
      return;
    }
    final int index = _indexNotifier!.value;
    final String label = _grades[index];
    widget.onPicked(Grade(system: GradeSystem.yds, value: label));
    _removeOverlay();
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

class _GradePopup extends StatelessWidget {
  const _GradePopup({
    required this.top,
    required this.left,
    required this.width,
    required this.itemHeight,
    required this.grades,
    required this.indexListenable,
    required this.onCancel,
    required this.onCommit,
  });

  final double top;
  final double left;
  final double width;
  final double itemHeight;
  final List<String> grades;
  final ValueListenable<int> indexListenable;
  final VoidCallback onCancel;
  final void Function(int index) onCommit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(onTap: onCancel),
        ),
        Positioned(
          top: top,
          left: left,
          child: Material(
            elevation: 8,
            color: scheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: width,
              height: math.min(
                itemHeight * grades.length,
                MediaQuery.of(context).size.height - top - 12,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double perItemHeight = constraints.maxHeight / grades.length;
                  return GestureDetector(
                    onPanDown: (DragDownDetails d) => _updateFromLocal(d.localPosition.dy, context),
                    onPanUpdate: (DragUpdateDetails d) => _updateFromLocal(d.localPosition.dy, context),
                    onPanEnd: (_) => onCommit(indexListenable.value),
                    onTapUp: (TapUpDetails d) {
                      _updateFromLocal(d.localPosition.dy, context);
                      onCommit(indexListenable.value);
                    },
                    child: ValueListenableBuilder<int>(
                      valueListenable: indexListenable,
                      builder: (BuildContext context, int current, _) {
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: grades.length,
                          itemBuilder: (BuildContext context, int i) {
                            final bool active = i == current;
                            return Container(
                              height: perItemHeight,
                              color: active ? scheme.primary.withValues(alpha: 0.12) : null,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                grades[i],
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateFromLocal(double localDy, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final double constrainedDy = localDy.clamp(0.0, size.height);
    final double perItem = size.height / grades.length;
    final int index = (constrainedDy / perItem)
        .floor()
        .clamp(0, grades.length - 1);
    if (indexListenable is ValueNotifier<int>) {
      final ValueNotifier<int> vn = indexListenable as ValueNotifier<int>;
      if (vn.value != index) {
        vn.value = index;
      }
    }
  }
}

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


