import 'package:go_router/go_router.dart';

import '../../profile/presentation/pages/purchased_notes_page.dart';
import '../presentation/pages/note_categories_page.dart';
import '../presentation/pages/note_details_page.dart';
import '../presentation/pages/notes_list_page.dart';

/// Route paths + GoRoute definitions owned by this feature, following
/// the same per-feature pattern as `competition/routes/competition_routes.dart`.
///
/// `library` renders the profile feature's existing `PurchasedNotesPage`
/// rather than a new page - "notes already bought" is the exact same
/// data (`ApiConstants.profilePurchasedNotes` / `PurchasedNote`) whether
/// it's reached from Account or from here, so this reuses it instead of
/// duplicating a second "my notes" list. Mirrors how `category` rides
/// along inside the competition feature instead of getting its own
/// feature folder (see `CompetitionInjection`'s doc comment).
class StudyNotesRoutes {
  StudyNotesRoutes._();

  static const String home = '/study-notes';
  static const String list = 'list'; // nested under `home`: /study-notes/list
  static const String details = 'details/:id'; // nested under `list`: /study-notes/list/details/:id
  static const String library = 'library'; // nested under `home`: /study-notes/library

  static String listPath({String? categoryId}) =>
      categoryId == null ? '$home/$list' : '$home/$list?category=$categoryId';
  static String detailsPath(String id) => '$home/$list/details/$id';
  static String libraryPath = '$home/$library';

  static List<RouteBase> get routes => [
        GoRoute(
          path: home,
          name: 'studyNotes',
          builder: (context, state) => const NoteCategoriesPage(),
          routes: [
            GoRoute(
              path: list,
              name: 'studyNotesList',
              // `extra` carries the category display name (set by
              // `NoteCategoriesPage._openCategory`) so the app bar has a
              // title immediately; the `category` query param is what
              // actually filters the fetched notes.
              builder: (context, state) => NotesListPage(
                categoryId: state.uri.queryParameters['category'],
                categoryLabel: state.extra as String?,
              ),
              routes: [
                GoRoute(
                  path: details,
                  name: 'studyNoteDetails',
                  builder: (context, state) => NoteDetailsPage(
                    noteId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: library,
              name: 'studyNotesLibrary',
              builder: (context, state) => const PurchasedNotesPage(),
            ),
          ],
        ),
      ];
}
