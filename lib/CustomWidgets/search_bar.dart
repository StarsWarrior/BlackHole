/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final bool isYt;
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
    super.key,
    this.leading,
    this.hintText,
    this.showClose = true,
    this.autofocus = false,
    this.onQueryChanged,
    required this.body,
    required this.isYt,
    required this.controller,
    required this.liveSearch,
    required this.onSubmitted,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  String tempQuery = '';
  String query = '';
  final ValueNotifier<bool> hide = ValueNotifier<bool>(true);
  final ValueNotifier<List> suggestionsList = ValueNotifier<List>([]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.body,
        ValueListenableBuilder(
          valueListenable: hide,
          builder: (
            BuildContext context,
            bool hidden,
            Widget? child,
          ) {
            return Visibility(
              visible: !hidden,
              child: GestureDetector(
                onTap: () {
                  hide.value = true;
                },
              ),
            );
          },
        ),
        Column(
          children: [
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
                          ? ValueListenableBuilder(
                              valueListenable: hide,
                              builder: (
                                BuildContext context,
                                bool hidden,
                                Widget? child,
                              ) {
                                return Visibility(
                                  visible: !hidden,
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      widget.controller.text = '';
                                      suggestionsList.value = [];
                                    },
                                  ),
                                );
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
                        hide.value = false;
                        if (widget.isYt) {
                          Future.delayed(
                            const Duration(
                              milliseconds: 400,
                            ),
                            () async {
                              if (tempQuery == val &&
                                  tempQuery.trim() != '' &&
                                  tempQuery != query) {
                                query = tempQuery;
                                suggestionsList.value =
                                    await widget.onQueryChanged!(tempQuery)
                                        as List;
                              }
                            },
                          );
                        } else {
                          Future.delayed(
                            const Duration(
                              milliseconds: 600,
                            ),
                            () async {
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
                      }
                    },
                    onSubmitted: (submittedQuery) {
                      if (submittedQuery.trim() != '') {
                        query = submittedQuery;
                        widget.onSubmitted(submittedQuery);
                        if (!hide.value) hide.value = true;
                      }
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: hide,
              builder: (
                BuildContext context,
                bool hidden,
                Widget? child,
              ) {
                return Visibility(
                  visible: !hidden,
                  child: ValueListenableBuilder(
                    valueListenable: suggestionsList,
                    builder: (
                      BuildContext context,
                      List suggestedList,
                      Widget? child,
                    ) {
                      return suggestedList.isEmpty
                          ? const SizedBox()
                          : Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  10.0,
                                ),
                              ),
                              elevation: 8.0,
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 250.0,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemExtent: 70.0,
                                  itemCount: suggestedList.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading:
                                          const Icon(CupertinoIcons.search),
                                      title: Text(
                                        suggestedList[index].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        widget.onSubmitted(
                                          suggestedList[index].toString(),
                                        );
                                        hide.value = true;
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
