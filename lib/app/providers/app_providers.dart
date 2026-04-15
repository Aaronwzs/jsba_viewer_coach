import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:jsba_app/app/viewmodel/app_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';
import 'package:jsba_app/app/utils/responsive_helper.dart';

class ResponsiveInfo extends ChangeNotifier {
  DeviceType _deviceType = DeviceType.mobile;
  double _screenWidth = 0;

  DeviceType get deviceType => _deviceType;
  double get screenWidth => _screenWidth;
  bool get isMobile => _deviceType == DeviceType.mobile;
  bool get isTablet => _deviceType == DeviceType.tablet;
  bool get isWeb => _deviceType == DeviceType.web;

  void update(BuildContext context) {
    _deviceType = ResponsiveHelper.getDeviceType(context);
    _screenWidth = MediaQuery.sizeOf(context).width;
    notifyListeners();
  }
}

List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthViewModel()),
  ChangeNotifierProvider(create: (_) => AppViewModel()),
  ChangeNotifierProvider(create: (_) => OpenCourtViewModel()),
  ChangeNotifierProvider(create: (_) => ResponsiveInfo()),
];
