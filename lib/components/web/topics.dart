import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import 'package:memorare/components/web/topic_card_color.dart';
import 'package:memorare/state/topics_colors.dart';
import 'package:memorare/types/topic_color.dart';
import 'package:memorare/utils/route_names.dart';
import 'package:memorare/utils/router.dart';

List<TopicColor> _topics = [];

class Topics extends StatefulWidget {
  @override
  _TopicsState createState() => _TopicsState();
}

class _TopicsState extends State<Topics> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF2F2F2),
      padding: EdgeInsets.symmetric(vertical: 90.0, horizontal: 80.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: Text(
              'TOPICS',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ),

          SizedBox(
            width: 50.0,
            child: Divider(thickness: 2.0,),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 70.0),
            child: Opacity(
              opacity: .6,
              child: Text(
                '3 Topics you might like'
              ),
            ),
          ),

          SizedBox(
            width: 400.0,
            height: 200.0,
            child: topicsColorsCards(),
          ),

          FlatButton(
            onPressed: () {
              FluroRouter.router.navigateTo(context, TopicsRoute);
            },
            child: Opacity(
              opacity: .6,
              child: Text(
                'Discover more topics'
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget topicsColorsCards() {
    int count = 0;

    return Observer(
      builder: (context) {
        if (_topics.length == 0) {
          _topics = appTopicsColors.shuffle(max: 3);
        }

        return GridView.count(
          crossAxisCount: 3,
          childAspectRatio: .8,
          children: _topics.map((topicColor) {
            count++;

            return FadeInY(
              beginY: 50.0,
              endY: 0.0,
              delay: count.toDouble(),
              child: TopicCardColor(
                color: Color(topicColor.decimal),
                name: '${topicColor.name.substring(0, 1).toUpperCase()}${topicColor.name.substring(1)}',
              ),
            );

          }).toList(),
        );
      },
    );
  }
}
