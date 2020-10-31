import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figstyle/components/empty_content.dart';
import 'package:figstyle/components/error_container.dart';
import 'package:figstyle/components/loading_animation.dart';
import 'package:figstyle/components/quote_row_with_actions.dart';
import 'package:figstyle/state/colors.dart';
import 'package:figstyle/state/user_state.dart';
import 'package:figstyle/types/enums.dart';
import 'package:figstyle/types/quote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecentHero extends StatefulWidget {
  @override
  _RecentHeroState createState() => _RecentHeroState();
}

class _RecentHeroState extends State<RecentHero> {
  bool hasErrors = false;
  bool isConnected = false;
  bool isLoading = false;

  final limit = 6;
  final scrollController = ScrollController();

  List<Quote> quotes = [];

  String lang = 'en';

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingView();
    }

    if (!isLoading && hasErrors) {
      return errorView();
    }

    if (quotes.length == 0) {
      return emptyView();
    }

    return body();
  }

  Widget body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        quotidianRow(),
        gridView(),
      ],
    );
  }

  Widget quotidianRow() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24.0,
        left: 80.0,
      ),
      child: Wrap(
        spacing: 20.0,
        runSpacing: 20.0,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.wb_sunny),
            label: Text(
              "Tap here to see today quote",
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              primary: stateColors.secondary,
            ),
            icon: FaIcon(FontAwesomeIcons.random),
            label: Text(
              "Random quotes",
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingView() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: LoadingAnimation(),
    );
  }

  Widget emptyView() {
    return EmptyContent(
      icon: Opacity(
        opacity: .8,
        child: Icon(
          Icons.sentiment_neutral,
          size: 120.0,
          color: Color(0xFFFF005C),
        ),
      ),
      title: "There's no recent quotes",
      subtitle: "Maybe your this language has been added recently",
      onRefresh: () => fetch(),
    );
  }

  Widget errorView() {
    return Padding(
      padding: const EdgeInsets.only(top: 150.0),
      child: ErrorContainer(
        onRefresh: () => fetch(),
      ),
    );
  }

  Widget gridView() {
    return Observer(builder: (context) {
      final isConnected = userState.isUserConnected;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: 1000.0,
            padding: const EdgeInsets.only(
              left: 80.0,
              right: 80.0,
              top: 40.0,
            ),
            child: Wrap(
              spacing: 40.0,
              runSpacing: 40.0,
              children: quotes.map((quote) {
                return QuoteRowWithActions(
                  quote: quote,
                  elevation: 4.0,
                  showAuthor: true,
                  isConnected: isConnected,
                  componentType: ItemComponentType.card,
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  Future fetch() async {
    setState(() {
      isLoading = true;
      quotes.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .where('lang', isEqualTo: lang)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => isLoading = false);

        return;
      }

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        final quote = Quote.fromJSON(data);
        quotes.add(quote);
      });

      setState(() => isLoading = false);
    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoading = false;
      });
    }
  }
}
