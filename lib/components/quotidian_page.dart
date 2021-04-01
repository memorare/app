import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fig_style/components/user_lists.dart';
import 'package:fig_style/router/app_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:fig_style/actions/favourites.dart';
import 'package:fig_style/actions/share.dart';
import 'package:fig_style/components/full_page_loading.dart';
import 'package:fig_style/state/topics_colors.dart';
import 'package:fig_style/state/user.dart';
import 'package:fig_style/types/quotidian.dart';
import 'package:fig_style/utils/animation.dart';
import 'package:fig_style/screens/quote_page.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

String _prevLang;

class QuotidianPage extends StatefulWidget {
  final bool noAuth;

  QuotidianPage({
    this.noAuth = false,
  });

  @override
  _QuotidianPageState createState() => _QuotidianPageState();
}

class _QuotidianPageState extends State<QuotidianPage> {
  bool isPrevFav = false;
  bool hasFetchedFav = false;
  bool isLoading = false;
  bool isMenuOn = false;

  Quotidian quotidian;

  ReactionDisposer disposeFav;
  ReactionDisposer disposeLang;

  TextDecoration dashboardLinkDecoration = TextDecoration.none;

  @override
  void initState() {
    super.initState();

    disposeLang = autorun((_) {
      if (quotidian != null && _prevLang == stateUser.lang) {
        return;
      }

      _prevLang = stateUser.lang;
      fetch();
    });

    disposeFav = autorun((_) {
      final updatedAt = stateUser.updatedFavAt;
      fetchIsFav(updatedAt: updatedAt);
    });
  }

  @override
  void dispose() {
    if (disposeLang != null) {
      disposeLang();
    }

    if (disposeFav != null) {
      disposeFav();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && quotidian == null) {
      return FullPageLoading(
        title: 'Loading quotidian...',
      );
    }

    if (quotidian == null) {
      return emptyContainer();
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 70.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            quoteActions(),
                            Expanded(
                              child: quoteName(
                                screenWidth: MediaQuery.of(context).size.width,
                              ),
                            ),
                          ],
                        ),
                        animatedDivider(),
                        authorName(),
                        if (quotidian.quote.reference?.name != null &&
                            quotidian.quote.reference.name.length > 0)
                          referenceName(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget animatedDivider() {
    final topicColor = appTopicsColors.find(quotidian.quote.topics.first);
    final color = topicColor != null ? Color(topicColor.decimal) : Colors.white;

    return CustomAnimation(
      delay: 1.seconds,
      duration: 1.seconds,
      tween: Tween(begin: 0.0, end: 200.0),
      child: Divider(
        color: color,
        thickness: 2.0,
      ),
      builder: (context, child, value) {
        return SizedBox(
          width: value,
          child: child,
        );
      },
    );
  }

  Widget authorName() {
    return CustomAnimation(
      delay: 1.seconds,
      duration: 1.seconds,
      tween: Tween(begin: 0.0, end: 0.8),
      builder: (context, child, value) {
        return Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          final author = quotidian.quote.author;

          AuthorPageRoute(
            authorId: author.id,
            authorName: author.name,
          ).show(context);
        },
        child: Text(
          quotidian.quote.author.name,
          style: TextStyle(
            fontSize: 25.0,
          ),
        ),
      ),
    );
  }

  Widget emptyContainer() {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.warning,
            size: 40.0,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Sorry, an unexpected error happended :(',
              style: TextStyle(
                fontSize: 35.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget quoteActions() {
    return Observer(builder: (context) {
      if (!stateUser.isUserConnected) {
        return Padding(
          padding: EdgeInsets.zero,
        );
      }

      return Column(
        children: <Widget>[
          IconButton(
            onPressed: () async {
              if (isPrevFav) {
                removeQuotidianFromFav();
                return;
              }

              addQuotidianToFav();
            },
            icon:
                isPrevFav ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: IconButton(
              onPressed: () async {
                ShareActions.shareQuote(
                  context: context,
                  quote: quotidian.quote,
                );
              },
              icon: Icon(Icons.share),
            ),
          ),
          IconButton(
            tooltip: "Add to list...",
            onPressed: () => showCupertinoModalBottomSheet(
              context: context,
              builder: (context) => UserLists(
                scrollController: ModalScrollController.of(context),
                quote: quotidian.quote,
              ),
            ),
            icon: Icon(Icons.playlist_add),
          ),
        ],
      );
    });
  }

  Widget quoteName({double screenWidth}) {
    return Padding(
      padding: const EdgeInsets.only(left: 60.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => QuotePage(quoteId: quotidian.quote.id)));
        },
        child: createHeroQuoteAnimation(
          quote: quotidian.quote,
          screenWidth: screenWidth,
        ),
      ),
    );
  }

  Widget referenceName() {
    return CustomAnimation(
      delay: 2.seconds,
      duration: 1.seconds,
      tween: Tween(begin: 0.0, end: 0.6),
      child: GestureDetector(
        onTap: () {
          final reference = quotidian.quote.reference;

          context.router.push(
            ReferencesDeepRoute(children: [
              ReferencePageRoute(
                referenceId: reference.id,
                referenceName: reference.name,
              )
            ]),
          );
        },
        child: Text(
          quotidian.quote.reference.name,
          style: TextStyle(
            fontSize: 18.0,
          ),
        ),
      ),
      builder: (context, child, value) {
        return Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Opacity(
              opacity: value,
              child: child,
            ));
      },
    );
  }

  void addQuotidianToFav() async {
    setState(() {
      // Optimistic result
      isPrevFav = true;
    });

    final result = await FavActions.add(
      context: context,
      quotidian: quotidian,
    );

    if (!result) {
      setState(() {
        isPrevFav = false;
      });
    }
  }

  void fetchIsFav({DateTime updatedAt}) async {
    if (quotidian == null) {
      return;
    }

    final isCurrentFav = await FavActions.isFav(
      quoteId: quotidian.quote.id,
    );

    if (isPrevFav != isCurrentFav) {
      isPrevFav = isCurrentFav;
      setState(() {});
    }
  }

  void fetch() async {
    setState(() {
      isLoading = true;
    });

    final now = DateTime.now();

    String month = now.month.toString();
    month = month.length == 2 ? month : '0$month';

    String day = now.day.toString();
    day = day.length == 2 ? day : '0$day';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('quotidians')
          .doc('${now.year}:$month:$day:$_prevLang')
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
        });

        return;
      }

      setState(() {
        quotidian = Quotidian.fromJSON(doc.data());
        isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('error => $error');
      debugPrint(stackTrace.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  void removeQuotidianFromFav() async {
    setState(() {
      // Optimistic result
      isPrevFav = false;
    });

    final result = await FavActions.remove(
      context: context,
      quotidian: quotidian,
    );

    if (!result) {
      setState(() {
        isPrevFav = true;
      });
    }
  }
}
