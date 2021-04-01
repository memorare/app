import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fig_style/components/reference_card.dart';
import 'package:fig_style/components/fade_in_x.dart';
import 'package:fig_style/screens/references.dart';
import 'package:fig_style/types/reference.dart';

List<Reference> _references = [];

class DiscoverReferences extends StatefulWidget {
  @override
  _DiscoverReferencesState createState() => _DiscoverReferencesState();
}

class _DiscoverReferencesState extends State<DiscoverReferences> {
  bool isLoading = false;

  @override
  initState() {
    super.initState();

    if (_references.length > 0) {
      return;
    }
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(
          vertical: 90.0,
          horizontal: 80.0,
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Text(
                'DISCOVER',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
            SizedBox(
              width: 50.0,
              child: Divider(
                thickness: 2.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Opacity(
                opacity: .6,
                child: Text('Do you know these references?'),
              ),
            ),
            cardsItems(),
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: allReferencesButton(),
            ),
          ],
        ));
  }

  Widget allReferencesButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => References(),
        ),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(7.0),
          ),
        ),
        primary: Colors.black12,
      ),
      icon: Opacity(opacity: 0.6, child: Icon(Icons.list)),
      label: Opacity(
        opacity: .6,
        child: Text('All references'),
      ),
    );
  }

  Widget cardsItems() {
    List<Widget> cards = [];
    int count = 0;

    for (var reference in _references) {
      count += 100;

      cards.add(
        FadeInX(
          beginX: 130.0,
          endX: 0.0,
          delay: Duration(seconds: count),
          child: ReferenceCard(
            id: reference.id,
            imageUrl: reference.urls.image,
            name: reference.name,
            height: 290.0,
            width: 210.0,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 80.0,
      runSpacing: 80.0,
      children: cards,
    );
  }

  /// Fetch references
  void fetch() async {
    if (!this.mounted) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final refsSnapshot = await FirebaseFirestore.instance
          .collection('references')
          .orderBy('updatedAt', descending: true)
          .limit(3)
          .get();

      if (refsSnapshot.docs.isNotEmpty) {
        refsSnapshot.docs.forEach((doc) {
          final data = doc.data();
          data['id'] = doc.id;

          final ref = Reference.fromJSON(data);
          _references.add(ref);
        });
      }

      if (!this.mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      debugPrint(error.toString());

      setState(() {
        isLoading = false;
      });
    }
  }
}
