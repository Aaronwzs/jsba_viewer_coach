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
              child: child ?? const SizedBox(),
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
