import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/viewmodel/app_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/coach_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/announcement_view_model.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/viewmodel/availability_view_model.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';
import 'package:jsba_app/app/viewmodel/pwa_view_model.dart';
import 'package:jsba_app/app/widgets/pwa_install_banner.dart';
import 'package:jsba_app/app/widgets/offline_banner.dart';
import 'package:jsba_app/app/widgets/pwa_update_banner.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AppViewModel()),
        ChangeNotifierProvider(create: (_) => CoachViewModel()),
        ChangeNotifierProvider(create: (_) => ParentViewModel()),
        ChangeNotifierProvider(create: (_) => AnnouncementViewModel()),
        ChangeNotifierProvider(create: (_) => OpenCourtViewModel()),
        ChangeNotifierProvider(create: (_) => BillingViewModel()),
        ChangeNotifierProvider(create: (_) => AvailabilityViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => PwaViewModel()),
      ],
      child: const AppWrapper(),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final _router = AppRouter();
  final _appTheme = AppTheme();

  @override
  void initState() {
    super.initState();
    setupEasyLoading();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final easyLoadingInitializer = EasyLoading.init(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.0),
              ),
              child: _PwaBanners(child: child ?? const SizedBox()),
            );
          },
        );
        return easyLoadingInitializer(context, child);
      },
      theme: _appTheme.lightTheme,
      darkTheme: _appTheme.darkTheme,
      themeMode: _appTheme.themeMode,
      routerConfig: _router.config(),
    );
  }

  void setupEasyLoading() {
    EasyLoading.instance.userInteractions = false;
    EasyLoading.instance.maskType = EasyLoadingMaskType.black;
  }
}

/// Inner widget that orchestrates PWA banners (install, offline, update).
class _PwaBanners extends StatefulWidget {
  const _PwaBanners({required this.child});

  final Widget child;

  @override
  State<_PwaBanners> createState() => _PwaBannersState();
}

class _PwaBannersState extends State<_PwaBanners> {
  bool _updateBannerShown = false;

  @override
  void initState() {
    super.initState();
    // Listen for update-available events after a short delay to ensure
    // the widget tree is fully built before showing a snackbar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForUpdates();
    });
  }

  void _listenForUpdates() {
    final pwaVm = context.read<PwaViewModel>();
    pwaVm.addListener(_onPwaStateChanged);
  }

  void _onPwaStateChanged() {
    final pwaVm = context.read<PwaViewModel>();
    // Reset the guard when update is no longer available
    // so future updates can trigger the banner again.
    if (!pwaVm.updateAvailable) {
      _updateBannerShown = false;
      return;
    }
    if (!_updateBannerShown && mounted) {
      _updateBannerShown = true;
      PwaUpdateBanner.show(context);
    }
  }

  @override
  void dispose() {
    // Remove listener safely
    try {
      context.read<PwaViewModel>().removeListener(_onPwaStateChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OfflineBanner(),
        const PwaInstallBanner(),
        Expanded(child: widget.child),
      ],
    );
  }
}
