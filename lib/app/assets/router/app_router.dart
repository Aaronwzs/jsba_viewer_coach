import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:jsba_app/app/view/pages.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashScreenRoute.page, initial: true, path: '/'),
    AutoRoute(page: AcademyDashboardRoute.page, path: '/academy-dashboard'),
    AutoRoute(page: LoginLandingRoute.page, path: '/login-landing'),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: FirstTimeLoginRoute.page, path: '/first-time-login'),
    AutoRoute(page: ResetPasswordRoute.page, path: '/reset-password'),
    AutoRoute(
      page: CoachMainRoute.page,
      path: '/coach-main',
      children: [
        AutoRoute(
          page: CoachDashboardRoute.page,
          initial: true,
          maintainState: false,
        ),
        AutoRoute(page: SessionsRoute.page, maintainState: false),
        AutoRoute(page: PlayersRoute.page, maintainState: false),
        AutoRoute(page: CoachBillingRoute.page, maintainState: false),
        AutoRoute(page: SettingsRoute.page, maintainState: false),
      ],
    ),
    AutoRoute(
      page: ParentMainRoute.page,
      path: '/parent-main',
      children: [
        AutoRoute(
          page: ParentDashboardRoute.page,
          initial: true,
          maintainState: false,
        ),
        AutoRoute(page: MyReportsRoute.page, maintainState: false),
        AutoRoute(page: CourtBookingsRoute.page, maintainState: false),
        AutoRoute(page: ParentInvoicesRoute.page, maintainState: false),
        AutoRoute(page: SettingsRoute.page, maintainState: false),
      ],
    ),
    AutoRoute(page: VerificationRoute.page, path: '/verification'),
    AutoRoute(page: OtpRoute.page, path: '/otp'),
    AutoRoute(page: SessionDetailsRoute.page, path: '/session-details/:id'),
    AutoRoute(page: CreateSessionRoute.page, path: '/create-session'),
    AutoRoute(page: AttendanceRoute.page, path: '/attendance/:id'),
    AutoRoute(page: PlayerDetailsRoute.page, path: '/player-details/:id'),
    AutoRoute(page: CoachingProgramRoute.page, path: '/coaching-program'),
    AutoRoute(
      page: CreateCoachingProgramRoute.page,
      path: '/create-coaching-program',
    ),
    AutoRoute(page: MatchResultsRoute.page, path: '/match-results'),
    AutoRoute(page: RecordMatchRoute.page, path: '/record-match'),
    AutoRoute(page: AddChildRoute.page, path: '/add-child'),
    AutoRoute(page: ChildDetailsRoute.page, path: '/child-details/:id'),
    AutoRoute(page: PlayerReportRoute.page, path: '/player-report/:id'),
    AutoRoute(page: CreateBookingRoute.page, path: '/create-booking'),
    AutoRoute(page: SessionSlotsRoute.page, path: '/session-slots'),
    AutoRoute(page: InvoiceDetailsRoute.page, path: '/invoice-details/:id'),
    AutoRoute(page: ReceiptDetailsRoute.page, path: '/receipt-details/:id'),
    AutoRoute(page: AnnouncementsRoute.page, path: '/announcements'),
    AutoRoute(
      page: AnnouncementDetailsRoute.page,
      path: '/announcement-details/:id',
    ),
    AutoRoute(page: NotificationsRoute.page, path: '/notifications'),
    AutoRoute(page: EditProfileRoute.page, path: '/edit-profile'),
    AutoRoute(page: ChangePasswordRoute.page, path: '/change-password'),
    AutoRoute(page: OpenCourtDetailRoute.page, path: '/open-court-detail/:id'),
    AutoRoute(page: ClassDetailRoute.page, path: '/class-detail/:trainingId'),
  ];
}
