import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoAdaptiveScaffold extends StatelessWidget {
  const CupertinoAdaptiveScaffold({
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: title,
        trailing: actions == null ? null : Row(mainAxisSize: MainAxisSize.min, children: actions!),
      ),
      child: SafeArea(child: body),
    );
  }
}

class CupertinoAdaptiveCard extends StatelessWidget {
  const CupertinoAdaptiveCard({
    super.key,
    required this.child,
    required this.radius,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
      ),
      child: content,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: onTap == null ? card : GestureDetector(onTap: onTap, child: card),
    );
  }
}

class CupertinoAdaptiveIconButton extends StatelessWidget {
  const CupertinoAdaptiveIconButton({super.key, required this.icon, required this.onPressed});

  final Icon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: icon,
    );
  }
}

class CupertinoAdaptiveFilledButtonIcon extends StatelessWidget {
  const CupertinoAdaptiveFilledButtonIcon({super.key, required this.onPressed, required this.icon, required this.label});

  final VoidCallback onPressed;
  final Icon icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
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
}

class CupertinoAdaptiveSwitch extends StatelessWidget {
  const CupertinoAdaptiveSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(value: value, onChanged: onChanged);
  }
}

class CupertinoAdaptiveTextField extends StatelessWidget {
  const CupertinoAdaptiveTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}


