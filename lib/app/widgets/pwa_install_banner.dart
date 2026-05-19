import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/pwa_view_model.dart';

/// A banner widget that prompts the user to install the PWA when the browser
/// fires the `beforeinstallprompt` event.
///
/// Only visible on supported browsers when the app is not already installed.
class PwaInstallBanner extends StatelessWidget {
  const PwaInstallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PwaViewModel>(
      builder: (context, pwaVm, _) {
        if (!pwaVm.canInstall) return const SizedBox.shrink();

        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          leading: Icon(
            Icons.download_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          content: Text(
            'Install JSBA app for quick access',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.maybeOf(context)?.hideCurrentMaterialBanner();
              },
              child: Text(
                'Not now',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                pwaVm.promptInstall();
              },
              child: const Text('Install'),
            ),
          ],
        );
      },
    );
  }
}
