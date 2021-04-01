import 'package:fig_style/components/discover_desktop.dart';
import 'package:fig_style/components/recent_hero.dart';
import 'package:flutter/material.dart';
import 'package:fig_style/components/footer.dart';
import 'package:fig_style/components/desktop_app_bar.dart';
import 'package:fig_style/components/topics.dart';
import 'package:supercharged/supercharged.dart';

class HomeDesktop extends StatefulWidget {
  @override
  _HomeDesktopState createState() => _HomeDesktopState();
}

class _HomeDesktopState extends State<HomeDesktop> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          DesktopAppBar(
            title: "fig.style",
            padding: const EdgeInsets.only(left: 65.0),
            onTapIconHeader: () {
              scrollController.animateTo(
                0,
                duration: 250.milliseconds,
                curve: Curves.decelerate,
              );
            },
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              RecentHero(),
              DiscoverDesktop(),
              Topics(),
              Footer(
                pageScrollController: scrollController,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
