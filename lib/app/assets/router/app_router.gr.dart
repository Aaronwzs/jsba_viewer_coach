// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AcademyDashboardPage]
class AcademyDashboardRoute extends PageRouteInfo<void> {
  const AcademyDashboardRoute({List<PageRouteInfo>? children})
    : super(AcademyDashboardRoute.name, initialChildren: children);

  static const String name = 'AcademyDashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AcademyDashboardPage();
    },
  );
}

/// generated route for
/// [AcademyPage]
class AcademyRoute extends PageRouteInfo<void> {
  const AcademyRoute({List<PageRouteInfo>? children})
    : super(AcademyRoute.name, initialChildren: children);

  static const String name = 'AcademyRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AcademyPage();
    },
  );
}

/// generated route for
/// [AddChildPage]
class AddChildRoute extends PageRouteInfo<void> {
  const AddChildRoute({List<PageRouteInfo>? children})
    : super(AddChildRoute.name, initialChildren: children);

  static const String name = 'AddChildRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddChildPage();
    },
  );
}

/// generated route for
/// [AnnouncementDetailsPage]
class AnnouncementDetailsRoute extends PageRouteInfo<void> {
  const AnnouncementDetailsRoute({List<PageRouteInfo>? children})
    : super(AnnouncementDetailsRoute.name, initialChildren: children);

  static const String name = 'AnnouncementDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AnnouncementDetailsPage();
    },
  );
}

/// generated route for
/// [AnnouncementsPage]
class AnnouncementsRoute extends PageRouteInfo<void> {
  const AnnouncementsRoute({List<PageRouteInfo>? children})
    : super(AnnouncementsRoute.name, initialChildren: children);

  static const String name = 'AnnouncementsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AnnouncementsPage();
    },
  );
}

/// generated route for
/// [AttendancePage]
class AttendanceRoute extends PageRouteInfo<AttendanceRouteArgs> {
  AttendanceRoute({
    Key? key,
    required String trainingId,
    List<PageRouteInfo>? children,
  }) : super(
         AttendanceRoute.name,
         args: AttendanceRouteArgs(key: key, trainingId: trainingId),
         initialChildren: children,
       );

  static const String name = 'AttendanceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AttendanceRouteArgs>();
      return AttendancePage(key: args.key, trainingId: args.trainingId);
    },
  );
}

class AttendanceRouteArgs {
  const AttendanceRouteArgs({this.key, required this.trainingId});

  final Key? key;

  final String trainingId;

  @override
  String toString() {
    return 'AttendanceRouteArgs{key: $key, trainingId: $trainingId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AttendanceRouteArgs) return false;
    return key == other.key && trainingId == other.trainingId;
  }

  @override
  int get hashCode => key.hashCode ^ trainingId.hashCode;
}

/// generated route for
/// [ChangePasswordPage]
class ChangePasswordRoute extends PageRouteInfo<void> {
  const ChangePasswordRoute({List<PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChangePasswordPage();
    },
  );
}

/// generated route for
/// [ChildDetailsPage]
class ChildDetailsRoute extends PageRouteInfo<void> {
  const ChildDetailsRoute({List<PageRouteInfo>? children})
    : super(ChildDetailsRoute.name, initialChildren: children);

  static const String name = 'ChildDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChildDetailsPage();
    },
  );
}

/// generated route for
/// [ClassDetailPage]
class ClassDetailRoute extends PageRouteInfo<ClassDetailRouteArgs> {
  ClassDetailRoute({
    Key? key,
    required String trainingId,
    List<PageRouteInfo>? children,
  }) : super(
         ClassDetailRoute.name,
         args: ClassDetailRouteArgs(key: key, trainingId: trainingId),
         initialChildren: children,
       );

  static const String name = 'ClassDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ClassDetailRouteArgs>();
      return ClassDetailPage(key: args.key, trainingId: args.trainingId);
    },
  );
}

class ClassDetailRouteArgs {
  const ClassDetailRouteArgs({this.key, required this.trainingId});

  final Key? key;

  final String trainingId;

  @override
  String toString() {
    return 'ClassDetailRouteArgs{key: $key, trainingId: $trainingId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClassDetailRouteArgs) return false;
    return key == other.key && trainingId == other.trainingId;
  }

  @override
  int get hashCode => key.hashCode ^ trainingId.hashCode;
}

/// generated route for
/// [CoachBillingPage]
class CoachBillingRoute extends PageRouteInfo<void> {
  const CoachBillingRoute({List<PageRouteInfo>? children})
    : super(CoachBillingRoute.name, initialChildren: children);

  static const String name = 'CoachBillingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CoachBillingPage();
    },
  );
}

/// generated route for
/// [CoachDashboardPage]
class CoachDashboardRoute extends PageRouteInfo<void> {
  const CoachDashboardRoute({List<PageRouteInfo>? children})
    : super(CoachDashboardRoute.name, initialChildren: children);

  static const String name = 'CoachDashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CoachDashboardPage();
    },
  );
}

/// generated route for
/// [CoachMainPage]
class CoachMainRoute extends PageRouteInfo<void> {
  const CoachMainRoute({List<PageRouteInfo>? children})
    : super(CoachMainRoute.name, initialChildren: children);

  static const String name = 'CoachMainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CoachMainPage();
    },
  );
}

/// generated route for
/// [CoachingProgramPage]
class CoachingProgramRoute extends PageRouteInfo<void> {
  const CoachingProgramRoute({List<PageRouteInfo>? children})
    : super(CoachingProgramRoute.name, initialChildren: children);

  static const String name = 'CoachingProgramRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CoachingProgramPage();
    },
  );
}

/// generated route for
/// [CourtBookingsPage]
class CourtBookingsRoute extends PageRouteInfo<void> {
  const CourtBookingsRoute({List<PageRouteInfo>? children})
    : super(CourtBookingsRoute.name, initialChildren: children);

  static const String name = 'CourtBookingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CourtBookingsPage();
    },
  );
}

/// generated route for
/// [CreateBookingPage]
class CreateBookingRoute extends PageRouteInfo<void> {
  const CreateBookingRoute({List<PageRouteInfo>? children})
    : super(CreateBookingRoute.name, initialChildren: children);

  static const String name = 'CreateBookingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateBookingPage();
    },
  );
}

/// generated route for
/// [CreateCoachingProgramPage]
class CreateCoachingProgramRoute extends PageRouteInfo<void> {
  const CreateCoachingProgramRoute({List<PageRouteInfo>? children})
    : super(CreateCoachingProgramRoute.name, initialChildren: children);

  static const String name = 'CreateCoachingProgramRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateCoachingProgramPage();
    },
  );
}

/// generated route for
/// [CreateSessionPage]
class CreateSessionRoute extends PageRouteInfo<void> {
  const CreateSessionRoute({List<PageRouteInfo>? children})
    : super(CreateSessionRoute.name, initialChildren: children);

  static const String name = 'CreateSessionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateSessionPage();
    },
  );
}

/// generated route for
/// [EditProfilePage]
class EditProfileRoute extends PageRouteInfo<void> {
  const EditProfileRoute({List<PageRouteInfo>? children})
    : super(EditProfileRoute.name, initialChildren: children);

  static const String name = 'EditProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EditProfilePage();
    },
  );
}

/// generated route for
/// [FaqPage]
class FaqRoute extends PageRouteInfo<void> {
  const FaqRoute({List<PageRouteInfo>? children})
    : super(FaqRoute.name, initialChildren: children);

  static const String name = 'FaqRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FaqPage();
    },
  );
}

/// generated route for
/// [FeedbackReportPage]
class FeedbackReportRoute extends PageRouteInfo<void> {
  const FeedbackReportRoute({List<PageRouteInfo>? children})
    : super(FeedbackReportRoute.name, initialChildren: children);

  static const String name = 'FeedbackReportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FeedbackReportPage();
    },
  );
}

/// generated route for
/// [FirstTimeLoginPage]
class FirstTimeLoginRoute extends PageRouteInfo<void> {
  const FirstTimeLoginRoute({List<PageRouteInfo>? children})
    : super(FirstTimeLoginRoute.name, initialChildren: children);

  static const String name = 'FirstTimeLoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FirstTimeLoginPage();
    },
  );
}

/// generated route for
/// [InvoiceDetailsPage]
class InvoiceDetailsRoute extends PageRouteInfo<InvoiceDetailsRouteArgs> {
  InvoiceDetailsRoute({
    Key? key,
    required String id,
    List<PageRouteInfo>? children,
  }) : super(
         InvoiceDetailsRoute.name,
         args: InvoiceDetailsRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'InvoiceDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<InvoiceDetailsRouteArgs>(
        orElse: () => InvoiceDetailsRouteArgs(id: pathParams.getString('id')),
      );
      return InvoiceDetailsPage(key: args.key, id: args.id);
    },
  );
}

class InvoiceDetailsRouteArgs {
  const InvoiceDetailsRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'InvoiceDetailsRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InvoiceDetailsRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [LoginLandingPage]
class LoginLandingRoute extends PageRouteInfo<void> {
  const LoginLandingRoute({List<PageRouteInfo>? children})
    : super(LoginLandingRoute.name, initialChildren: children);

  static const String name = 'LoginLandingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginLandingPage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MatchResultsPage]
class MatchResultsRoute extends PageRouteInfo<void> {
  const MatchResultsRoute({List<PageRouteInfo>? children})
    : super(MatchResultsRoute.name, initialChildren: children);

  static const String name = 'MatchResultsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MatchResultsPage();
    },
  );
}

/// generated route for
/// [MyReportsPage]
class MyReportsRoute extends PageRouteInfo<void> {
  const MyReportsRoute({List<PageRouteInfo>? children})
    : super(MyReportsRoute.name, initialChildren: children);

  static const String name = 'MyReportsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MyReportsPage();
    },
  );
}

/// generated route for
/// [NotificationsPage]
class NotificationsRoute extends PageRouteInfo<void> {
  const NotificationsRoute({List<PageRouteInfo>? children})
    : super(NotificationsRoute.name, initialChildren: children);

  static const String name = 'NotificationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotificationsPage();
    },
  );
}

/// generated route for
/// [OpenCourtDetailPage]
class OpenCourtDetailRoute extends PageRouteInfo<OpenCourtDetailRouteArgs> {
  OpenCourtDetailRoute({
    Key? key,
    required String sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         OpenCourtDetailRoute.name,
         args: OpenCourtDetailRouteArgs(key: key, sessionId: sessionId),
         initialChildren: children,
       );

  static const String name = 'OpenCourtDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OpenCourtDetailRouteArgs>();
      return OpenCourtDetailPage(key: args.key, sessionId: args.sessionId);
    },
  );
}

class OpenCourtDetailRouteArgs {
  const OpenCourtDetailRouteArgs({this.key, required this.sessionId});

  final Key? key;

  final String sessionId;

  @override
  String toString() {
    return 'OpenCourtDetailRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OpenCourtDetailRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [OtpPage]
class OtpRoute extends PageRouteInfo<OtpRouteArgs> {
  OtpRoute({
    Key? key,
    required String phoneNumber,
    List<PageRouteInfo>? children,
  }) : super(
         OtpRoute.name,
         args: OtpRouteArgs(key: key, phoneNumber: phoneNumber),
         initialChildren: children,
       );

  static const String name = 'OtpRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OtpRouteArgs>();
      return OtpPage(key: args.key, phoneNumber: args.phoneNumber);
    },
  );
}

class OtpRouteArgs {
  const OtpRouteArgs({this.key, required this.phoneNumber});

  final Key? key;

  final String phoneNumber;

  @override
  String toString() {
    return 'OtpRouteArgs{key: $key, phoneNumber: $phoneNumber}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtpRouteArgs) return false;
    return key == other.key && phoneNumber == other.phoneNumber;
  }

  @override
  int get hashCode => key.hashCode ^ phoneNumber.hashCode;
}

/// generated route for
/// [ParentDashboardPage]
class ParentDashboardRoute extends PageRouteInfo<void> {
  const ParentDashboardRoute({List<PageRouteInfo>? children})
    : super(ParentDashboardRoute.name, initialChildren: children);

  static const String name = 'ParentDashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ParentDashboardPage();
    },
  );
}

/// generated route for
/// [ParentInvoicesPage]
class ParentInvoicesRoute extends PageRouteInfo<void> {
  const ParentInvoicesRoute({List<PageRouteInfo>? children})
    : super(ParentInvoicesRoute.name, initialChildren: children);

  static const String name = 'ParentInvoicesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ParentInvoicesPage();
    },
  );
}

/// generated route for
/// [ParentMainPage]
class ParentMainRoute extends PageRouteInfo<void> {
  const ParentMainRoute({List<PageRouteInfo>? children})
    : super(ParentMainRoute.name, initialChildren: children);

  static const String name = 'ParentMainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ParentMainPage();
    },
  );
}

/// generated route for
/// [PhoneSignInPage]
class PhoneSignInRoute extends PageRouteInfo<void> {
  const PhoneSignInRoute({List<PageRouteInfo>? children})
    : super(PhoneSignInRoute.name, initialChildren: children);

  static const String name = 'PhoneSignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PhoneSignInPage();
    },
  );
}

/// generated route for
/// [PlayerDetailsPage]
class PlayerDetailsRoute extends PageRouteInfo<void> {
  const PlayerDetailsRoute({List<PageRouteInfo>? children})
    : super(PlayerDetailsRoute.name, initialChildren: children);

  static const String name = 'PlayerDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PlayerDetailsPage();
    },
  );
}

/// generated route for
/// [PlayerReportPage]
class PlayerReportRoute extends PageRouteInfo<PlayerReportRouteArgs> {
  PlayerReportRoute({
    Key? key,
    required String playerId,
    List<PageRouteInfo>? children,
  }) : super(
         PlayerReportRoute.name,
         args: PlayerReportRouteArgs(key: key, playerId: playerId),
         initialChildren: children,
       );

  static const String name = 'PlayerReportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PlayerReportRouteArgs>();
      return PlayerReportPage(key: args.key, playerId: args.playerId);
    },
  );
}

class PlayerReportRouteArgs {
  const PlayerReportRouteArgs({this.key, required this.playerId});

  final Key? key;

  final String playerId;

  @override
  String toString() {
    return 'PlayerReportRouteArgs{key: $key, playerId: $playerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayerReportRouteArgs) return false;
    return key == other.key && playerId == other.playerId;
  }

  @override
  int get hashCode => key.hashCode ^ playerId.hashCode;
}

/// generated route for
/// [PlayersPage]
class PlayersRoute extends PageRouteInfo<void> {
  const PlayersRoute({List<PageRouteInfo>? children})
    : super(PlayersRoute.name, initialChildren: children);

  static const String name = 'PlayersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PlayersPage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [ReceiptDetailsPage]
class ReceiptDetailsRoute extends PageRouteInfo<ReceiptDetailsRouteArgs> {
  ReceiptDetailsRoute({
    Key? key,
    required String id,
    List<PageRouteInfo>? children,
  }) : super(
         ReceiptDetailsRoute.name,
         args: ReceiptDetailsRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'ReceiptDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ReceiptDetailsRouteArgs>(
        orElse: () => ReceiptDetailsRouteArgs(id: pathParams.getString('id')),
      );
      return ReceiptDetailsPage(key: args.key, id: args.id);
    },
  );
}

class ReceiptDetailsRouteArgs {
  const ReceiptDetailsRouteArgs({this.key, required this.id});

  final Key? key;

  final String id;

  @override
  String toString() {
    return 'ReceiptDetailsRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReceiptDetailsRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [RecordMatchPage]
class RecordMatchRoute extends PageRouteInfo<void> {
  const RecordMatchRoute({List<PageRouteInfo>? children})
    : super(RecordMatchRoute.name, initialChildren: children);

  static const String name = 'RecordMatchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RecordMatchPage();
    },
  );
}

/// generated route for
/// [ResetPasswordPage]
class ResetPasswordRoute extends PageRouteInfo<void> {
  const ResetPasswordRoute({List<PageRouteInfo>? children})
    : super(ResetPasswordRoute.name, initialChildren: children);

  static const String name = 'ResetPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ResetPasswordPage();
    },
  );
}

/// generated route for
/// [RootNavigatorPage]
class RootNavigatorRoute extends PageRouteInfo<void> {
  const RootNavigatorRoute({List<PageRouteInfo>? children})
    : super(RootNavigatorRoute.name, initialChildren: children);

  static const String name = 'RootNavigatorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RootNavigatorPage();
    },
  );
}

/// generated route for
/// [SessionDetailsPage]
class SessionDetailsRoute extends PageRouteInfo<SessionDetailsRouteArgs> {
  SessionDetailsRoute({
    Key? key,
    String? sessionId,
    List<PageRouteInfo>? children,
  }) : super(
         SessionDetailsRoute.name,
         args: SessionDetailsRouteArgs(key: key, sessionId: sessionId),
         rawPathParams: {'sessionId': sessionId},
         initialChildren: children,
       );

  static const String name = 'SessionDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<SessionDetailsRouteArgs>(
        orElse: () => SessionDetailsRouteArgs(
          sessionId: pathParams.optString('sessionId'),
        ),
      );
      return SessionDetailsPage(key: args.key, sessionId: args.sessionId);
    },
  );
}

class SessionDetailsRouteArgs {
  const SessionDetailsRouteArgs({this.key, this.sessionId});

  final Key? key;

  final String? sessionId;

  @override
  String toString() {
    return 'SessionDetailsRouteArgs{key: $key, sessionId: $sessionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SessionDetailsRouteArgs) return false;
    return key == other.key && sessionId == other.sessionId;
  }

  @override
  int get hashCode => key.hashCode ^ sessionId.hashCode;
}

/// generated route for
/// [SessionSlotsPage]
class SessionSlotsRoute extends PageRouteInfo<void> {
  const SessionSlotsRoute({List<PageRouteInfo>? children})
    : super(SessionSlotsRoute.name, initialChildren: children);

  static const String name = 'SessionSlotsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SessionSlotsPage();
    },
  );
}

/// generated route for
/// [SessionsPage]
class SessionsRoute extends PageRouteInfo<void> {
  const SessionsRoute({List<PageRouteInfo>? children})
    : super(SessionsRoute.name, initialChildren: children);

  static const String name = 'SessionsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SessionsPage();
    },
  );
}

/// generated route for
/// [SettingsPage]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsPage();
    },
  );
}

/// generated route for
/// [SplashScreenPage]
class SplashScreenRoute extends PageRouteInfo<void> {
  const SplashScreenRoute({List<PageRouteInfo>? children})
    : super(SplashScreenRoute.name, initialChildren: children);

  static const String name = 'SplashScreenRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreenPage();
    },
  );
}

/// generated route for
/// [VerificationPage]
class VerificationRoute extends PageRouteInfo<void> {
  const VerificationRoute({List<PageRouteInfo>? children})
    : super(VerificationRoute.name, initialChildren: children);

  static const String name = 'VerificationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const VerificationPage();
    },
  );
}
