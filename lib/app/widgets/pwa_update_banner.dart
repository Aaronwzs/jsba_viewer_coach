import 'package:flutter/material.dart';
import 'package:jsba_app/app/service/pwa_service.dart';

/// A widget that shows a MaterialBanner when a new app version is available.
class PwaUpdateBanner {
  /// Show the update available snackbar on the given [context].
  static void show(BuildContext context) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        leading: Icon(
          Icons.system_update_rounded,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
        content: Text(
          'A new version is available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.maybeOf(context)
                  ?.hideCurrentMaterialBanner();
            },
            child: Text(
              'Later',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              ScaffoldMessenger.maybeOf(context)
                  ?.hideCurrentMaterialBanner();
              // Reload to apply the new version
              PwaService.applyUpdate();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
