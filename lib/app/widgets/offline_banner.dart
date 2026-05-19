import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/viewmodel/pwa_view_model.dart';

/// A banner widget that displays when the user is offline and hides when
/// connectivity is restored.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PwaViewModel>(
      builder: (context, pwaVm, _) {
        if (pwaVm.isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.error,
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onError,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline. Some features may be unavailable.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
