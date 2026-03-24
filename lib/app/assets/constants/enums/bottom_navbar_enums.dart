enum BottomNavbarType {
  home(0),
  sessions(1),
  players(1),
  myKids(1),
  bookings(1),
  billing(1),
  invoices(1),
  profile(2),
  announcements(3);

  final int value;
  const BottomNavbarType(this.value);

  String get title {
    switch (this) {
      case BottomNavbarType.home:
        return 'Home';
      case BottomNavbarType.sessions:
        return 'Sessions';
      case BottomNavbarType.players:
        return 'Players';
      case BottomNavbarType.myKids:
        return 'My Kids';
      case BottomNavbarType.bookings:
        return 'Bookings';
      case BottomNavbarType.billing:
        return 'Billing';
      case BottomNavbarType.invoices:
        return 'Invoices';
      case BottomNavbarType.profile:
        return 'Profile';
      case BottomNavbarType.announcements:
        return 'Announcements';
    }
  }

  String get activeIconPath {
    switch (this) {
      case BottomNavbarType.home:
        return 'assets/icons/ic_home_active.png';
      case BottomNavbarType.sessions:
        return 'assets/icons/ic_calendar_active.png';
      case BottomNavbarType.players:
        return 'assets/icons/ic_players_active.png';
      case BottomNavbarType.myKids:
        return 'assets/icons/ic_kids_active.png';
      case BottomNavbarType.bookings:
        return 'assets/icons/ic_bookings_active.png';
      case BottomNavbarType.billing:
        return 'assets/icons/ic_billing_active.png';
      case BottomNavbarType.invoices:
        return 'assets/icons/ic_invoices_active.png';
      case BottomNavbarType.profile:
        return 'assets/icons/ic_profile_active.png';
      case BottomNavbarType.announcements:
        return 'assets/icons/ic_announcements_active.png';
    }
  }

  String get inactiveIconPath {
    switch (this) {
      case BottomNavbarType.home:
        return 'assets/icons/ic_home_inactive.png';
      case BottomNavbarType.sessions:
        return 'assets/icons/ic_calendar_inactive.png';
      case BottomNavbarType.players:
        return 'assets/icons/ic_players_inactive.png';
      case BottomNavbarType.myKids:
        return 'assets/icons/ic_kids_inactive.png';
      case BottomNavbarType.bookings:
        return 'assets/icons/ic_bookings_inactive.png';
      case BottomNavbarType.billing:
        return 'assets/icons/ic_billing_inactive.png';
      case BottomNavbarType.invoices:
        return 'assets/icons/ic_invoices_inactive.png';
      case BottomNavbarType.profile:
        return 'assets/icons/ic_profile_inactive.png';
      case BottomNavbarType.announcements:
        return 'assets/icons/ic_announcements_inactive.png';
    }
  }
}

enum UserRole { coach, parent }