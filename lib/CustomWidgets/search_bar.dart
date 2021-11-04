import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final Widget body;
  final bool autofocus;
  final bool liveSearch;
  final bool showClose;
  final Widget? leading;
  final String? hintText;
  final TextEditingController controller;
  final Function(String)? onQueryChanged;
  final Function(String) onSubmitted;
  const SearchBar({
    Key? key,
    this.leading,
    this.hintText,
    this.showClose = true,
    this.autofocus = false,
    this.onQueryChanged,
    required this.body,
    required this.controller,
    required this.liveSearch,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  String tempQuery = '';
  String query = '';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.body,
        Card(
          margin: const EdgeInsets.fromLTRB(
            18.0,
            10.0,
            18.0,
            15.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10.0,
            ),
          ),
          elevation: 8.0,
          child: SizedBox(
            height: 52.0,
            child: Center(
              child: TextField(
                controller: widget.controller,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.5,
                      color: Colors.transparent,
                    ),
                  ),
                  fillColor: Theme.of(context).colorScheme.secondary,
                  prefixIcon: widget.leading,
                  suffixIcon: widget.showClose
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            widget.controller.text = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  hintText: widget.hintText,
                ),
                autofocus: widget.autofocus,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onChanged: (val) {
                  if (widget.liveSearch) {
                    tempQuery = val;
                    Future.delayed(
                      const Duration(
                        milliseconds: 600,
                      ),
                      () {
                        if (tempQuery == val &&
                            tempQuery.trim() != '' &&
                            tempQuery != query) {
                          query = tempQuery;
                          if (widget.onQueryChanged == null) {
                            widget.onSubmitted(tempQuery);
                          } else {
                            widget.onQueryChanged!(tempQuery);
                          }
                        }
                      },
                    );
                  }
                },
                onSubmitted: (_query) {
                  if (_query.trim() != '') {
                    query = _query;
                    widget.onSubmitted(_query);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
