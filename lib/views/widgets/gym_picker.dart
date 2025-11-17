import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const List<String> kDefaultGyms = <String>[
  'Mission Cliffs',
  'Dogpatch Boulders',
  'Planet Granite Sunnyvale',
  'Touchstone Sacramento',
];

Future<String?> showHomeGymPicker(BuildContext context, {List<String> gyms = kDefaultGyms}) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return await showCupertinoModalPopup<String>(
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
                      filtered = gyms.where((String g) => g.toLowerCase().contains(query.toLowerCase())).toList();
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
                                onPressed: () => Navigator.of(ctx).pop(g),
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
  }
  // Material bottom sheet with search
  return await showModalBottomSheet<String>(
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
                  decoration: const InputDecoration(hintText: 'Search gyms', prefixIcon: Icon(Icons.search)),
                  onChanged: (String v) {
                    innerSet(() {
                      query = v;
                      filtered = gyms.where((String g) => g.toLowerCase().contains(query.toLowerCase())).toList();
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
                              onTap: () => Navigator.of(sheetCtx).pop(g),
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


