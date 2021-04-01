import 'package:flutter/material.dart';
import 'package:fig_style/screens/add_quote/help/utils.dart';

class HelpTopics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 500.0,
          child: Opacity(
            opacity: .6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextBlock(
                  text: 'Topics are used to categorize the quote.',
                ),
                TextBlock(
                  text: 'You must select one or more topics.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
