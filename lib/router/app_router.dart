import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:figstyle/screens/about.dart';
import 'package:figstyle/screens/add_quote/steps.dart';
import 'package:figstyle/screens/author_page.dart';
import 'package:figstyle/screens/authors.dart';
import 'package:figstyle/screens/contact.dart';
import 'package:figstyle/screens/dashboard_page.dart';
import 'package:figstyle/screens/drafts.dart';
import 'package:figstyle/screens/favourites.dart';
import 'package:figstyle/screens/forgot_password.dart';
import 'package:figstyle/screens/home/home.dart';
import 'package:figstyle/screens/my_published_quotes.dart';
import 'package:figstyle/screens/my_temp_quotes.dart';
import 'package:figstyle/screens/quotes_list.dart';
import 'package:figstyle/screens/quotes_lists.dart';
import 'package:figstyle/screens/reference_page.dart';
import 'package:figstyle/screens/references.dart';
import 'package:figstyle/screens/search.dart';
import 'package:figstyle/screens/settings.dart';
import 'package:figstyle/screens/signin.dart';
import 'package:figstyle/screens/signup.dart';
import 'package:figstyle/screens/topic_page.dart';
import 'package:figstyle/screens/tos.dart';

export 'app_router.gr.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: Home),
    MaterialRoute(path: '/about', page: About),
    // AutoRoute(
    //   path: 'admin',
    //   page: EmptyRouterPage,
    //   name: 'AdminDeepRoute',
    //   children: [
    //     RedirectRoute(path: '', redirectTo: 'temp'),
    //     AutoRoute(path: 'temp', page: AdminTempQuotes),
    //     AutoRoute(path: 'quotidians', page: Quotidians),
    //   ],
    // ),
    AutoRoute(
      path: '/authors',
      page: EmptyRouterPage,
      name: 'AuthorsDeepRoute',
      children: [
        MaterialRoute(path: '', page: Authors),
        MaterialRoute(path: ':authorId', page: AuthorPage),
      ],
    ),
    MaterialRoute(path: '/contact', page: Contact),
    // AutoRoute(
    //   path: 'quotes',
    //   page: EmptyRouterPage,
    //   name: 'QuotesDeepRoute',
    //   children: [
    //     RedirectRoute(path: '', redirectTo: 'recent'),
    //     AutoRoute(path: 'recent', page: RecentQuotes),
    //   ],
    // ),
    AutoRoute(
      path: '/dashboard',
      page: DashboardPage,
      children: [
        RedirectRoute(path: '', redirectTo: 'fav'),
        AutoRoute(path: 'addquote', page: AddQuoteSteps),
        AutoRoute(path: 'drafts', page: Drafts),
        AutoRoute(path: 'fav', page: Favourites),
        AutoRoute(
          path: 'lists',
          page: EmptyRouterPage,
          name: 'QuotesListsDeepRoute',
          children: [
            AutoRoute(path: '', page: QuotesLists),
            AutoRoute(path: ':listId', page: QuotesList),
          ],
        ),
        AutoRoute(path: 'published', page: MyPublishedQuotes),
        AutoRoute(path: 'temp', page: MyTempQuotes),
      ],
    ),
    AutoRoute(
      path: '/topics',
      page: EmptyRouterPage,
      name: 'TopicsDeepRoute',
      children: [
        MaterialRoute(path: ':topicName', page: TopicPage),
      ],
    ),
    MaterialRoute(path: '/forgotpassword', page: ForgotPassword),
    AutoRoute(
      path: '/references',
      page: EmptyRouterPage,
      name: 'ReferencesDeepRoute',
      children: [
        MaterialRoute(path: '', page: References),
        MaterialRoute(path: ':referenceId', page: ReferencePage),
      ],
    ),
    MaterialRoute(path: '/settings', page: Settings),
    MaterialRoute(path: '/search', page: Search),
    MaterialRoute(path: '/signin', page: Signin),
    MaterialRoute(path: '/signup', page: Signup),
    MaterialRoute(path: '/tos', page: Tos),
    // RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $AppRouter {}
