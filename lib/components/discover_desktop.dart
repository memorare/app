import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fig_style/router/app_router.dart';
import 'package:fig_style/screens/authors.dart';
import 'package:fig_style/state/colors.dart';
import 'package:fig_style/state/user.dart';
import 'package:fig_style/types/author.dart';
import 'package:fig_style/types/enums.dart';
import 'package:fig_style/types/quote.dart';
import 'package:flutter/material.dart';
import 'package:fig_style/screens/references.dart';
import 'package:fig_style/types/reference.dart';
import 'package:mobx/mobx.dart';

Map<Reference, Quote> _referencesMap = {};
Map<Author, Quote> _authorsMap = {};

class DiscoverDesktop extends StatefulWidget {
  @override
  _DiscoverDesktopState createState() => _DiscoverDesktopState();
}

class _DiscoverDesktopState extends State<DiscoverDesktop> {
  bool isLoading = false;

  final cardWidth = 600.0;
  final limit = 6;
  final paddingRightAvatar = 24.0;

  String lang = 'en';
  final String defaultLang = 'en';

  int currentDiscoverItems = 0;
  int maxDiscoverItems = 3;

  ReactionDisposer langReaction;

  @override
  initState() {
    super.initState();
    initProps();

    if (_referencesMap.length == 0 || _authorsMap.length == 0) {
      lang = stateUser.lang;
      fetch();
    }
  }

  void initProps() {
    langReaction = reaction((_) => stateUser.lang, (newLang) {
      lang = newLang;
      fetch();
    });
  }

  @override
  void dispose() {
    langReaction?.reaction?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 60.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                bottom: 20.0,
              ),
              child: Opacity(
                opacity: 0.6,
                child: Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 60.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            authorsListView(),
            referencesListView(),
            Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                top: 10.0,
                bottom: 60.0,
              ),
              child: Wrap(
                spacing: 20.0,
                children: [
                  roundedButton(
                    icon: Icons.refresh,
                    textValue: 'Refresh',
                    onPressed: fetch,
                  ),
                  roundedButton(
                    textValue: 'All references',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => References(),
                        ),
                      );
                    },
                  ),
                  roundedButton(
                    textValue: 'All authors',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Authors(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Widget roundedButton({
    @required String textValue,
    @required VoidCallback onPressed,
    IconData icon = Icons.list,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
        ),
        primary: Colors.black12,
      ),
      icon: Opacity(
          opacity: 0.6,
          child: Icon(
            icon,
            color: stateColors.foreground,
          )),
      label: Text(
        textValue,
        style: TextStyle(
          color: stateColors.foreground,
        ),
      ),
    );
  }

  Widget authorAvatar(String imageUrl, Quote quote) {
    return Material(
      elevation: 4.0,
      shape: CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: Ink.image(
        image: NetworkImage(imageUrl),
        width: 80.0,
        height: 100.0,
        fit: BoxFit.cover,
        child: InkWell(
          onTap: () => goToAuthor(quote),
        ),
      ),
    );
  }

  Widget authorsListView() {
    List<Widget> children = [];

    _authorsMap.forEach((author, quote) {
      children.add(
        Container(
          width: cardWidth,
          padding: const EdgeInsets.only(bottom: 8.0),
          child: itemCard(
            quote: quote,
            imageUrl: author.urls.image,
            type: DiscoverType.authors,
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget itemCard({
    @required Quote quote,
    @required String imageUrl,
    DiscoverType type = DiscoverType.references,
  }) {
    return Card(
      elevation: 0.0,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTapQuote(quote),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(right: paddingRightAvatar),
                child: type == DiscoverType.authors
                    ? authorAvatar(imageUrl, quote)
                    : referenceAvatar(imageUrl, quote),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 16.0,
                        bottom: 8.0,
                      ),
                      child: Opacity(
                        opacity: 0.8,
                        child: Text(
                          quote.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Opacity(
                        opacity: 0.6,
                        child: InkWell(
                          onTap: () => goToAuthor(quote),
                          child: Text(
                            '― ${quote.author.name}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (quote.reference != null)
                      Align(
                        alignment: Alignment.topRight,
                        child: Opacity(
                          opacity: 0.6,
                          child: InkWell(
                            onTap: () => goToReference(quote),
                            child: Text(
                              quote.reference.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget referenceAvatar(String imageUrl, Quote quote) {
    return Card(
      elevation: 2.0,
      child: Ink.image(
        image: NetworkImage(imageUrl),
        width: 80.0,
        height: 100.0,
        fit: BoxFit.cover,
        child: InkWell(
          onTap: () => goToReference(quote),
        ),
      ),
    );
  }

  Widget referencesListView() {
    List<Widget> children = [];

    _referencesMap.forEach((ref, quote) {
      children.add(
        Container(
          width: cardWidth,
          padding: EdgeInsets.only(bottom: 8.0),
          child: itemCard(
            quote: quote,
            imageUrl: ref.urls.image,
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void fetch() async {
    if (!this.mounted) {
      return;
    }

    setState(() {
      _authorsMap.clear();
      _referencesMap.clear();
      currentDiscoverItems = 0;
      isLoading = true;
    });

    await Future.wait([
      fetchReferences(),
      fetchAuthors(),
    ]);

    if (!this.mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> fetchAuthors() async {
    if (!this.mounted) {
      return true;
    }

    final date = DateTime.now();
    final createdAt = date.subtract(Duration(days: Random().nextInt(90)));

    try {
      final authorSnap = await FirebaseFirestore.instance
          .collection('authors')
          .where('createdAt', isGreaterThanOrEqualTo: createdAt)
          .limit(limit)
          .get();

      if (authorSnap.docs.isEmpty) {
        return false;
      }

      for (var authorDoc in authorSnap.docs) {
        if (currentDiscoverItems >= maxDiscoverItems) {
          return true;
        }

        final authorData = authorDoc.data();
        authorData['id'] = authorDoc.id;

        final author = Author.fromJSON(authorData);

        final quoteSnap = await FirebaseFirestore.instance
            .collection('quotes')
            .where('author.id', isEqualTo: authorDoc.id)
            .where('lang', isEqualTo: lang)
            .limit(1)
            .get();

        if (quoteSnap.docs.isEmpty) {
          return false;
        }

        final quoteData = quoteSnap.docs.first.data();
        quoteData['id'] = quoteSnap.docs.first.id;

        final quote = Quote.fromJSON(quoteData);
        _authorsMap.putIfAbsent(author, () => quote);
        currentDiscoverItems++;
      }

      if (!this.mounted) {
        return true;
      }

      return true;
    } catch (error) {
      debugPrint(error.toString());

      return false;
    }
  }

  Future<bool> fetchReferences() async {
    if (!this.mounted) {
      return true;
    }

    final date = DateTime.now();
    final createdAt = date.subtract(Duration(days: Random().nextInt(90)));

    try {
      final refSnap = await FirebaseFirestore.instance
          .collection('references')
          .where('createdAt', isGreaterThanOrEqualTo: createdAt)
          .limit(limit)
          .get();

      if (refSnap.docs.isEmpty) {
        return false;
      }

      for (var refDoc in refSnap.docs) {
        if (currentDiscoverItems >= maxDiscoverItems) {
          return true;
        }

        final refData = refDoc.data();
        refData['id'] = refDoc.id;

        final ref = Reference.fromJSON(refData);
        final hasKey =
            _referencesMap.keys.any((element) => element.id == ref.id);

        if (hasKey) {
          continue;
        }

        final quoteSnap = await FirebaseFirestore.instance
            .collection('quotes')
            .where('reference.id', isEqualTo: refDoc.id)
            .where('lang', isEqualTo: lang)
            .limit(1)
            .get();

        if (quoteSnap.docs.isEmpty) {
          return false;
        }

        final quoteData = quoteSnap.docs.first.data();
        quoteData['id'] = quoteSnap.docs.first.id;

        final quote = Quote.fromJSON(quoteData);
        _referencesMap.putIfAbsent(ref, () => quote);
        currentDiscoverItems++;
      }

      if (!this.mounted) {
        return true;
      }

      return true;
    } catch (error) {
      debugPrint(error.toString());
      return false;
    }
  }

  void goToAuthor(Quote quote) {
    final author = quote.author;
    if (author == null || author.id.isEmpty) {
      return;
    }

    context.router.root.push(
      AuthorsDeepRoute(children: [
        AuthorPageRoute(
          authorId: author.id,
          authorName: author.name,
          authorImageUrl: author.urls.image,
        ),
      ]),
    );
  }

  void goToReference(Quote quote) {
    final reference = quote.reference;

    if (reference == null || reference.id == null || reference.id.isEmpty) {
      return;
    }

    context.router.root.push(
      ReferencesDeepRoute(children: [
        ReferencePageRoute(
          referenceId: reference.id,
          referenceName: reference.name,
          referenceImageUrl: reference.urls.image,
        ),
      ]),
    );
  }

  void onTapQuote(Quote quote) {
    context.router.push(
      QuotesDeepRoute(children: [
        QuotePageRoute(
          quoteId: quote.id,
        )
      ]),
    );
  }
}
