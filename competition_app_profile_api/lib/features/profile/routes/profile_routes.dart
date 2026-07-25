/// Route *names* for the profile feature's five sub-pages. Not wired
/// into go_router as `GoRoute`s (mirrors `AccountPage._handleEditProfile`'s
/// "not yet added to go_router, push directly" precedent) — these pages
/// are pushed with `Navigator.of(context).push(MaterialPageRoute(...))`
/// from `AccountPage` instead. Kept as named constants anyway so any
/// future promotion to real `GoRoute`s has an agreed-upon path scheme.
class ProfileRoutes {
  ProfileRoutes._();

  static const String matchHistory = '/account/profile/matches';
  static const String statistics = '/account/profile/statistics';
  static const String badges = '/account/profile/badges';
  static const String transactions = '/account/profile/transactions';
  static const String purchasedNotes = '/account/profile/notes';
}
