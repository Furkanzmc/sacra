import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isCupertinoPlatform => defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

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

