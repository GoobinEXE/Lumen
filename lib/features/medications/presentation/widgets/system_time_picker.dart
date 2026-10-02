import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Horário no seletor que o sistema já usa: roda do Relógio no Apple,
/// relógio do Material no Android.
Future<TimeOfDay?> showSystemTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return _showAppleTimePicker(context, initialTime);
  }
  return showTimePicker(
    context: context,
    initialTime: initialTime,
    useRootNavigator: true,
  );
}

Future<TimeOfDay?> _showAppleTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
) {
  var selected = initialTime;
  final material = MaterialLocalizations.of(context);

  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      return Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(material.cancelButtonLabel),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: Text(material.okButtonLabel),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2020,
                  1,
                  1,
                  initialTime.hour,
                  initialTime.minute,
                ),
                use24hFormat: MediaQuery.of(ctx).alwaysUse24HourFormat,
                onDateTimeChanged: (value) {
                  selected = TimeOfDay(hour: value.hour, minute: value.minute);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
