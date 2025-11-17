import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/profile_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/adaptive.dart';
import 'settings_screen.dart';

final StateProvider<bool> _profileEditingProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileProvider);
    final bool isEditing = ref.watch(_profileEditingProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AdaptiveScaffold(
      title: const Text('Profile'),
      actions: <Widget>[
        AdaptiveIconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<Widget>(builder: (_) => const SettingsScreen()));
          },
          tooltip: 'Settings',
          icon: Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.gear_alt : Icons.settings),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.constrainedWidth(context)),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ProfilePhoto(
                    photoUrl: state.photoUrl,
                    initials: _initials(state.displayName),
                    isEditing: isEditing,
                    onTap: () async {
                      if (!isEditing) {
                        ref.read(_profileEditingProvider.notifier).state = true;
                        return;
                      }
                      await _showPhotoActions(context, ref);
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _LabeledField(
                          label: 'Name',
                          child: isEditing
                              ? _InlineEditableText(
                                  value: state.displayName,
                                  onChanged: (String v) => ref.read(profileProvider.notifier).updateName(v),
                                )
                              : Text(state.displayName, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _LabeledField(
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                          child: isEditing
                              ? _InlineEditableText(
                                  value: state.location ?? '',
                                  hintText: 'Add location',
                                  onChanged: (String v) => ref.read(profileProvider.notifier).updateLocation(v),
                                )
                              : Text(state.location ?? 'Not set', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _LabeledField(
                          label: 'Home Gym',
                          icon: Icons.fitness_center_outlined,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(state.homeGym ?? 'Not set', style: Theme.of(context).textTheme.bodyMedium),
                              ),
                              if (isEditing)
                                AdaptiveIconButton(
                                  onPressed: () => _pickHomeGym(context, ref),
                                  tooltip: 'Choose home gym',
                                  compact: true,
                                  icon: Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.search : Icons.search),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isEditing) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AdaptiveFilledButton.icon(
                    onPressed: () => ref.read(_profileEditingProvider.notifier).state = false,
                    icon: Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle),
                    label: const Text('Done'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Buddies', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              if (state.buddies.isEmpty)
                Text('No buddies yet', style: Theme.of(context).textTheme.bodySmall)
              else
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.buddies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final Buddy b = state.buddies[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: scheme.secondaryContainer,
                            backgroundImage: (b.avatarUrl == null || b.avatarUrl!.isEmpty) ? null : NetworkImage(b.avatarUrl!),
                            child: (b.avatarUrl == null || b.avatarUrl!.isEmpty)
                                ? Text(_initials(b.name), style: const TextStyle(fontWeight: FontWeight.w600))
                                : null,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 72,
                            child: Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.photoUrl, required this.initials, required this.isEditing, required this.onTap});
  final String? photoUrl;
  final String initials;
  final bool isEditing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: (photoUrl == null || photoUrl!.isEmpty) ? null : NetworkImage(photoUrl!),
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Text(initials, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700))
              : null,
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  isEditing ? (defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.photo_on_rectangle : Icons.photo_camera) : (defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.pencil : Icons.edit),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.icon});
  final String label;
  final Widget child;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: child),
      ],
    );
  }
}

class _InlineEditableText extends StatefulWidget {
  const _InlineEditableText({required this.value, required this.onChanged, this.hintText});
  final String value;
  final String? hintText;
  final ValueChanged<String> onChanged;
  @override
  State<_InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<_InlineEditableText> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _InlineEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextField(
      controller: _ctrl,
      labelText: widget.hintText,
      minLines: 1,
      maxLines: 1,
      onChanged: widget.onChanged,
    );
  }
}

String _initials(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
}

Future<void> _showPhotoActions(BuildContext context, WidgetRef ref) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: const Text('Profile Photo'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Placeholder: set a demo URL
              ref.read(profileProvider.notifier).updatePhotoUrl('https://avatars.githubusercontent.com/u/9919?s=200&v=4');
            },
            child: const Text('Upload photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(profileProvider.notifier).updatePhotoUrl(null);
            },
            isDestructiveAction: true,
            child: const Text('Remove photo'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Profile Photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Upload photo'),
            onTap: () {
              Navigator.of(ctx).pop();
              ref.read(profileProvider.notifier).updatePhotoUrl('https://avatars.githubusercontent.com/u/9919?s=200&v=4');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Remove photo'),
            onTap: () {
              Navigator.of(ctx).pop();
              ref.read(profileProvider.notifier).updatePhotoUrl(null);
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    ),
  );
}

Future<void> _pickHomeGym(BuildContext context, WidgetRef ref) async {
  const List<String> gyms = <String>[
    'Mission Cliffs',
    'Dogpatch Boulders',
    'Planet Granite Sunnyvale',
    'Touchstone Sacramento',
  ];
  final ProfileViewModel vm = ref.read(profileProvider.notifier);
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        String query = '';
        List<String> filtered = gyms;
        return StatefulBuilder(
          builder: (BuildContext ctx, void Function(void Function()) setState) {
            return CupertinoActionSheet(
              title: const Text('Choose home gym'),
              message: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CupertinoSearchTextField(
                  placeholder: 'Search gyms',
                  onChanged: (String v) {
                    setState(() {
                      query = v;
                      filtered = gyms
                          .where((String g) => g.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              actions: (filtered.isEmpty
                      ? <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: Text('No results')),
                          ),
                        ]
                      : filtered
                          .map((String g) => CupertinoActionSheetAction(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  vm.updateHomeGym(g);
                                },
                                child: Text(g),
                              ))
                          .toList())
                  .toList(),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop(),
                isDefaultAction: true,
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext sheetCtx) {
      String query = '';
      List<String> filtered = gyms;
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
          top: 8,
        ),
        child: StatefulBuilder(
          builder: (BuildContext innerCtx, void Function(void Function()) innerSet) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                Text('Choose home gym', style: Theme.of(innerCtx).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search gyms',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (String v) {
                    innerSet(() {
                      query = v;
                      filtered = gyms
                          .where((String g) => g.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: filtered.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No results')))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (BuildContext _, int i) {
                            final String g = filtered[i];
                            return ListTile(
                              title: Text(g),
                              onTap: () {
                                Navigator.of(sheetCtx).pop();
                                vm.updateHomeGym(g);
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      );
    },
  );
}
