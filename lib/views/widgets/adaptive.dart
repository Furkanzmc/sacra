import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertinoPlatform => defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

// Global adaptive design tokens
const double kCardBaseRadiusCupertino = 14;
const double kCardBaseRadiusMaterial = 12;
const double kCardCornerRadiusScale = 1.3; // +30%

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    if (_isCupertinoPlatform) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: title,
          trailing: actions == null
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ),
        child: SafeArea(child: body),
      );
    }
    return Scaffold(
      appBar: AppBar(title: title, actions: actions),
      body: body,
    );
  }
}

String adaptiveFormatTime(BuildContext context, DateTime dateTime) {
  if (_isCupertinoPlatform) {
    final bool use24h = MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    int hour = dateTime.hour;
    final int minute = dateTime.minute;
    if (use24h) {
      final String h = hour.toString().padLeft(2, '0');
      final String m = minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final String ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final String m = minute.toString().padLeft(2, '0');
    return '$hour:$m $ampm';
  }
  return TimeOfDay.fromDateTime(dateTime).format(context);
}

String adaptiveFormatDate(BuildContext context, DateTime dateTime) {
  // Simple cross-platform date formatter: "MMM d, yyyy"
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final String month = months[dateTime.month - 1];
  final String day = dateTime.day.toString();
  final String year = dateTime.year.toString();
  return '$month $day, $year';
}

class AdaptiveCard extends StatelessWidget {
  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final double base = _isCupertinoPlatform ? kCardBaseRadiusCupertino : kCardBaseRadiusMaterial;
    final double r = (borderRadius ?? base) * kCardCornerRadiusScale;
    if (_isCupertinoPlatform) {
      final Widget content = Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      );
      final Widget card = DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
        ),
        child: content,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: onTap == null ? card : GestureDetector(onTap: onTap, child: card),
      );
    }
    final Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    final Widget materialChild = onTap == null
        ? content
        : InkWell(onTap: onTap, child: content, borderRadius: BorderRadius.circular(r));
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r)),
      child: materialChild,
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  final Icon icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (_isCupertinoPlatform) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: icon,
      );
    }
    return IconButton(onPressed: onPressed, tooltip: tooltip, icon: icon);
  }
}

class AdaptiveFilledButton extends StatelessWidget {
  const AdaptiveFilledButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final Icon icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    if (_isCupertinoPlatform) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon,
            const SizedBox(width: 8),
            label,
          ],
        ),
      );
    }
    return FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (_isCupertinoPlatform) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }
    return Checkbox(value: value, onChanged: (bool? v) => onChanged(v ?? false));
  }
}

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? labelText;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    if (_isCupertinoPlatform) {
      return CupertinoTextField(
        controller: controller,
        placeholder: labelText,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
      );
    }
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

Future<void> showAdaptiveActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<MapEntry<T, String>> items,
  required void Function(T) onSelected,
}) async {
  if (_isCupertinoPlatform) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: items
            .map((MapEntry<T, String> item) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onSelected(item.key);
                  },
                  child: Text(item.value),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
    return;
  }
  // On Material, do nothing here; use PopupMenuButton inline.
}

