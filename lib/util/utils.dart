import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void handlePermissionDenial(BuildContext context, String permissionType) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("$permissionType Permission Required"),
        content: Text(
          "This feature requires $permissionType permission to work properly. "
              "Please enable it in the app settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text("Settings"),
          ),
        ],
      );
    },
  );
}
