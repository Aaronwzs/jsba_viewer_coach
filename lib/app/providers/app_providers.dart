import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:jsba_app/app/viewmodel/app_view_model.dart';
import 'package:jsba_app/app/viewmodel/auth_view_model.dart';
import 'package:jsba_app/app/viewmodel/open_court_view_model.dart';

List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthViewModel()),
  ChangeNotifierProvider(create: (_) => AppViewModel()),
  ChangeNotifierProvider(create: (_) => OpenCourtViewModel()),
];
