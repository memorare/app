import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String description;
  final Icon icon;
  final String title;
  final Function onRefresh;
  final Function onTapDescription;

  EmptyView({
    this.description = '',
    this.icon,
    this.onRefresh,
    this.onTapDescription,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          return await onRefresh();
        }
      },
      child: ListView(
        children: <Widget>[
          content(context),
        ],
      ),
    );
  }

  Widget content(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 100.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) icon,
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30.0,
              ),
            ),
          ),
          Opacity(
              opacity: 0.6,
              child: TextButton(
                onPressed: () {
                  if (onTapDescription != null) {
                    onTapDescription();
                  }
                },
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
