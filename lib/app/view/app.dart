import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';
import 'package:jsba_app/app/assets/router/app_router.dart';
import 'package:jsba_app/app/viewmodel/app_view_model.dart';
import 'package:jsba_app/app/viewmodel/assessment_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/coach_view_model.dart';
import 'package:jsba_app/app/viewmodel/parent_view_model.dart';
import 'package:jsba_app/app/viewmodel/announcement_view_model.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/viewmodel/availability_view_model.dart';
import 'package:jsba_app/app/model/notification_item_model.dart';
import 'package:jsba_app/app/viewmodel/notification_view_model.dart';
import 'package:jsba_app/app/viewmodel/pwa_view_model.dart';
import 'package:jsba_app/app/utils/starter_handler.dart' as starter_handler;
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
        ChangeNotifierProvider(
          create: (_) {
            final vm = AuthViewModel();
            // Fire auth resolution eagerly — on web reload the SplashScreen
            // guard is bypassed by auto_route URL restore, so no widget will
            // call checkAuth() unless we start it here.
            vm.checkAuth();
            return vm;
          },
        ),
        ChangeNotifierProvider(create: (_) => AppViewModel()),
        ChangeNotifierProvider(create: (_) => AssessmentViewModel()),
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
      _wireNotificationTap();
    });
  }

  void _listenForUpdates() {
    final pwaVm = context.read<PwaViewModel>();
    pwaVm.addListener(_onPwaStateChanged);
  }

  /// Wire the onNotificationTap callback so tapping a push notification
  /// in the system tray (background/cold-start) navigates to the relevant page.
  void _wireNotificationTap() {
    starter_handler.notificationService.onNotificationTap =
        (NotificationItemModel notification) {
          if (!mounted) return;

          // Best-effort: mark the matching notification(s) as read in the
          // in-app feed. The data payload only carries the entity reference
          // (referenceCollection + referenceId), not the Firestore doc ID,
          // so we use the by-reference helper. No-op if the VM is not
          // listening for the current user yet.
          if (notification.referenceCollection != null &&
              notification.referenceId != null) {
            context.read<NotificationViewModel>().markAsReadByReference(
                  referenceCollection: notification.referenceCollection,
                  referenceId: notification.referenceId,
                );
          }

          String? path;
          switch (notification.referenceCollection) {
            case 'announcements':
              path = '/announcement-details/${notification.referenceId}';
            case 'invoices':
              path = '/invoice-details/${notification.referenceId}';
            case 'receipts':
              path = '/receipt-details/${notification.referenceId}';
            case 'training':
              path = '/class-detail/${notification.referenceId}';
            case 'court_signups':
              path = '/open-court-detail/${notification.referenceId}';
            case 'kid_availability':
              // Navigate to the open court detail or general dashboard
              path = '/open-court-detail/${notification.referenceId}';
            case 'feedbacks':
              path = '/feedback-report';
            default:
              path = null;
          }

          if (path == null) return;
          if (!mounted) return;

          context.router.pushPath(path);
        };
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
    return Stack(
      children: [
        Column(
          children: [
            const OfflineBanner(),
            Expanded(child: widget.child),
          ],
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: PwaInstallBanner(),
        ),
      ],
    );
  }
}
