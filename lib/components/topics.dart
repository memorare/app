import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fig_style/components/quote_row_with_actions.dart';
import 'package:fig_style/router/app_router.gr.dart';
import 'package:fig_style/state/colors.dart';
import 'package:fig_style/state/user.dart';
import 'package:fig_style/types/quote.dart';
import 'package:fig_style/utils/language.dart';
import 'package:flutter/material.dart';
import 'package:fig_style/components/topic_card_color.dart';
import 'package:fig_style/state/topics_colors.dart';
import 'package:fig_style/types/topic_color.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

List<TopicColor> _topicsList = [];

class Topics extends StatefulWidget {
  @override
  _TopicsState createState() => _TopicsState();
}

class _TopicsState extends State<Topics> {
  bool isLoading = false;
  bool hasErrors = false;

  final quotesByTopicsList = <List<Quote>>[];
  final limit = 3;

  ReactionDisposer topicsDisposer;

  String lang = Language.en;

  @override
  initState() {
    super.initState();
    initProps();
  }

  void initProps() {
    topicsDisposer = autorun((reaction) {
      if (_topicsList.length == 0) {
        _topicsList = appTopicsColors.shuffle(max: limit);
      }

      lang = stateUser.lang;
      fetch();
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (topicsDisposer != null) {
      topicsDisposer.reaction.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 90.0,
        horizontal: 80.0,
      ),
      foregroundDecoration: BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          sectionTitle(),
          topicsAndQuotes(),
          allTopicsButton(),
        ],
      ),
    );
  }

  Widget allTopicsButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: ElevatedButton.icon(
        onPressed: () {
          final topicName = appTopicsColors.shuffle(max: 1).first.name;

          context.router.push(
            TopicsDeepRoute(
              children: [
                TopicPageRoute(
                  topicName: topicName,
                )
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(7.0),
            ),
          ),
          primary: Colors.black12,
        ),
        icon: Opacity(opacity: 0.6, child: Icon(Icons.filter_none)),
        label: Opacity(
          opacity: .6,
          child: Text('Discover more topics'),
        ),
      ),
    );
  }

  Widget sectionTitle() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20.0,
        top: 0.0,
      ),
      child: Opacity(
        opacity: 0.6,
        child: Text(
          'Topics',
          style: TextStyle(
            fontSize: 60.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget topicsAndQuotes() {
    return Observer(builder: (context) {
      final isConnected = stateUser.isUserConnected;
      final width = MediaQuery.of(context).size.width;

      double horizontal = 10.0;
      double quoteFontSize = 20.0;

      if (width < 390) {
        horizontal = 0.0;
        quoteFontSize = 16.0;
      }

      return Column(
        children: _topicsList.map((topic) {
          final index = _topicsList.indexOf(topic);
          final color = appTopicsColors.getColorFor(topic.name);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 40.0,
                ),
                child: TopicCardColor(
                  size: 50.0,
                  elevation: 6.0,
                  color: Color(topic.decimal),
                  name: topic.name,
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: quotesByTopicsList.length > 0
                    ? quotesByTopicsList[index].map((quote) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 700.0,
                          ),
                          child: QuoteRowWithActions(
                            quote: quote,
                            quoteFontSize: quoteFontSize,
                            color: stateColors.appBackground,
                            isConnected: isConnected,
                            leading: Container(
                              width: 15.0,
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Container(
                                width: 5.0,
                                decoration: ShapeDecoration(
                                  color: color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                ),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontal,
                            ),
                          ),
                        );
                      }).toList()
                    : [],
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  void fetch() async {
    if (!this.mounted) {
      return;
    }

    setState(() => isLoading = true);

    for (var i = 0; i < limit; i++) {
      await fetchTopicQuotes(i);
    }

    if (!this.mounted) {
      return;
    }
    setState(() => isLoading = false);
  }

  Future fetchTopicQuotes(int index) async {
    try {
      final topicName = _topicsList[index].name;

      final snapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .where('topics.$topicName', isEqualTo: true)
          .where('lang', isEqualTo: lang)
          .limit(3)
          .get();

      if (snapshot.docs.isEmpty) {
        if (!this.mounted) {
          return;
        }

        setState(() => isLoading = false);
        return;
      }

      final quotes = <Quote>[];

      snapshot.docs.forEach((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        quotes.add(Quote.fromJSON(data));
      });

      quotesByTopicsList.insert(index, quotes);
    } catch (error) {
      debugPrint(error.toString());
      hasErrors = true;
    }
  }
}
