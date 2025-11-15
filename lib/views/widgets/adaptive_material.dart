import 'package:flutter/material.dart';

class MaterialAdaptiveScaffold extends StatelessWidget {
  const MaterialAdaptiveScaffold({
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
    return Scaffold(appBar: AppBar(title: title, actions: actions), body: body);
  }
}

class MaterialAdaptiveCard extends StatelessWidget {
  const MaterialAdaptiveCard({super.key, required this.child, required this.radius, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    final Widget materialChild = onTap == null
        ? content
        : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: content);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: materialChild,
    );
  }
}

class MaterialAdaptiveIconButton extends StatelessWidget {
  const MaterialAdaptiveIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});
  final Icon icon;
  final VoidCallback onPressed;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onPressed, tooltip: tooltip, icon: icon);
  }
}

class MaterialAdaptiveFilledButtonIcon extends StatelessWidget {
  const MaterialAdaptiveFilledButtonIcon({super.key, required this.onPressed, required this.icon, required this.label});
  final VoidCallback onPressed;
  final Icon icon;
  final Widget label;
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

class MaterialAdaptiveSwitch extends StatelessWidget {
  const MaterialAdaptiveSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Checkbox(value: value, onChanged: (bool? v) => onChanged(v ?? false));
  }
}

class MaterialAdaptiveTextField extends StatelessWidget {
  const MaterialAdaptiveTextField({
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


