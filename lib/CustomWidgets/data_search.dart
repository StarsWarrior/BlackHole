import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DataSearch extends SearchDelegate {
  final List data;

  DataSearch(this.data);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      query.isEmpty
          ? IconButton(icon: Icon(CupertinoIcons.search), onPressed: () {})
          : IconButton(
              onPressed: () {
                query = "";
              },
              icon: Icon(
                Icons.clear_rounded,
              ),
            ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : data
            .where((element) => element['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Image(
                image: AssetImage('assets/cover.jpg'),
              ),
              suggestionList[index]['image'] == null
                  ? SizedBox()
                  : SizedBox(
                      height: 50.0,
                      width: 50.0,
                      child: Image(
                        fit: BoxFit.cover,
                        image: MemoryImage(suggestionList[index]['image']),
                      ),
                    )
            ],
          ),
        ),
        title: Text(
          suggestionList[index]['title'] != null &&
                  suggestionList[index]['title'].trim() != ""
              ? suggestionList[index]['title']
              : '${suggestionList[index]['id'].split('/').last}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index]['artist'] ?? "",
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false, // set to false
              pageBuilder: (_, __, ___) => PlayScreen(
                data: {
                  'response': suggestionList,
                  'index': index,
                  'offline': true
                },
                fromMiniplayer: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(
      primaryColor: Theme.of(context).accentColor,
      textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.white),
      hintColor: Colors.white70,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
      primaryColorBrightness: Brightness.dark,
      textTheme: theme.textTheme.copyWith(
        headline6:
            TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
      ),
      inputDecorationTheme:
          InputDecorationTheme(focusedBorder: InputBorder.none),
    );
  }
}
