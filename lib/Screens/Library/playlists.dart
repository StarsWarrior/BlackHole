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

import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/import_export_playlist.dart';
import 'package:blackhole/Screens/Library/import.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final Box settingsBox = Hive.box('settings');
  final List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() as List? ??
          ['Favorite Songs'];
  Map playlistDetails =
      Hive.box('settings').get('playlistDetails', defaultValue: {}) as Map;
  @override
  Widget build(BuildContext context) {
    if (!playlistNames.contains('Favorite Songs')) {
      playlistNames.insert(0, 'Favorite Songs');
      settingsBox.put('playlistNames', playlistNames);
    }

    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  AppLocalizations.of(context)!.playlists,
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondary,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.createPlaylist),
                      leading: SizedBox.square(
                        dimension: 50,
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                      onTap: () async {
                        await showTextInputDialog(
                          context: context,
                          title:
                              AppLocalizations.of(context)!.createNewPlaylist,
                          initialText: '',
                          keyboardType: TextInputType.name,
                          onSubmitted: (String value) async {
                            final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
                            value.replaceAll(avoid, '').replaceAll('  ', ' ');
                            if (value.trim() == '') {
                              value = 'Playlist ${playlistNames.length}';
                            }
                            while (playlistNames.contains(value) ||
                                await Hive.boxExists(value)) {
                              // ignore: use_string_buffers
                              value = '$value (1)';
                            }
                            playlistNames.add(value);
                            settingsBox.put('playlistNames', playlistNames);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.importPlaylist),
                      leading: SizedBox.square(
                        dimension: 50,
                        child: Center(
                          child: Icon(
                            MdiIcons.import,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                      ),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImportPlaylist(),
                          ),
                        );
                      },
                    ),
                    if (playlistNames.length > 1)
                      ListTile(
                        title:
                            Text(AppLocalizations.of(context)!.mergePlaylists),
                        leading: SizedBox.square(
                          dimension: 50,
                          child: Center(
                            child: Icon(
                              Icons.merge_type_rounded,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final List<int> checked = [];
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return StatefulBuilder(
                                builder: (
                                  BuildContext context,
                                  StateSetter setStt,
                                ) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        10.0,
                                      ),
                                    ),
                                    content: SizedBox(
                                      width: 500,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          30,
                                          0,
                                          10,
                                        ),
                                        itemCount: playlistNames.length,
                                        itemBuilder: (context, index) {
                                          final String name =
                                              playlistNames[index].toString();
                                          final String showName =
                                              playlistDetails.containsKey(name)
                                                  ? playlistDetails[name]
                                                              ['name']
                                                          ?.toString() ??
                                                      name
                                                  : name;
                                          return CheckboxListTile(
                                            activeColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            checkColor: Theme.of(context)
                                                        .colorScheme
                                                        .secondary ==
                                                    Colors.white
                                                ? Colors.black
                                                : null,
                                            value: checked.contains(index),
                                            onChanged: (value) {
                                              if (value ?? false) {
                                                checked.add(index);
                                              } else {
                                                checked.remove(index);
                                              }
                                              setStt(() {});
                                            },
                                            title: Text(
                                              showName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle:
                                                playlistDetails[name] == null ||
                                                        playlistDetails[name]
                                                                ['count'] ==
                                                            null ||
                                                        playlistDetails[name]
                                                                ['count'] ==
                                                            0
                                                    ? null
                                                    : Text(
                                                        '${playlistDetails[name]['count']} ${AppLocalizations.of(context)!.songs}',
                                                      ),
                                            secondary: (playlistDetails[
                                                            name] ==
                                                        null ||
                                                    playlistDetails[name]
                                                            ['imagesList'] ==
                                                        null ||
                                                    (playlistDetails[name]
                                                                ['imagesList']
                                                            as List)
                                                        .isEmpty)
                                                ? Card(
                                                    elevation: 5,
                                                    color: Colors.transparent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        7.0,
                                                      ),
                                                    ),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    child: SizedBox(
                                                      height: 50,
                                                      width: 50,
                                                      child: name ==
                                                              'Favorite Songs'
                                                          ? const Image(
                                                              image: AssetImage(
                                                                'assets/cover.jpg',
                                                              ),
                                                            )
                                                          : const Image(
                                                              image: AssetImage(
                                                                'assets/album.png',
                                                              ),
                                                            ),
                                                    ),
                                                  )
                                                : Collage(
                                                    imageList:
                                                        playlistDetails[name]
                                                                ['imagesList']
                                                            as List,
                                                    showGrid: true,
                                                    placeholderImage:
                                                        'assets/cover.jpg',
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .cancel,
                                        ),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary: Theme.of(context)
                                                      .colorScheme
                                                      .secondary ==
                                                  Colors.white
                                              ? Colors.black
                                              : null,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        onPressed: () async {
                                          try {
                                            final List<String>
                                                playlistsToMerge = checked
                                                    .map(
                                                      (int e) =>
                                                          playlistNames[e]
                                                              .toString(),
                                                    )
                                                    .toList();
                                            if (playlistsToMerge
                                                .contains('Favorite Songs')) {
                                              playlistsToMerge
                                                  .remove('Favorite Songs');
                                              playlistsToMerge.insert(
                                                0,
                                                'Favorite Songs',
                                              );
                                            }
                                            if (playlistsToMerge.length > 1) {
                                              final finalMap = {};
                                              for (final String playlistName
                                                  in playlistsToMerge
                                                      .sublist(1)) {
                                                try {
                                                  final Box playlistBox =
                                                      await Hive.openBox(
                                                    playlistName,
                                                  );
                                                  final Map _songsMap =
                                                      playlistBox.toMap();
                                                  finalMap.addAll(_songsMap);
                                                  await playlistDetails
                                                      .remove(playlistName);
                                                  playlistNames
                                                      .remove(playlistName);
                                                  await playlistBox
                                                      .deleteFromDisk();
                                                } catch (e) {
                                                  ShowSnackBar().showSnackBar(
                                                    context,
                                                    'Error merging $playlistName: $e',
                                                  );
                                                }
                                              }
                                              final Box finalPlaylistBox =
                                                  await Hive.openBox(
                                                playlistsToMerge.first,
                                              );
                                              finalPlaylistBox.putAll(finalMap);

                                              await settingsBox.put(
                                                'playlistDetails',
                                                playlistDetails,
                                              );

                                              await settingsBox.put(
                                                'playlistNames',
                                                playlistNames,
                                              );
                                            }
                                          } catch (e) {
                                            ShowSnackBar().showSnackBar(
                                              context,
                                              'Error: $e',
                                            );
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .ok,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(),
                      builder: (
                        BuildContext context,
                        Box box,
                        Widget? child,
                      ) {
                        final List playlistNamesValue = box.get(
                              'playlistNames',
                              defaultValue: ['Favorite Songs'],
                            )?.toList() as List? ??
                            ['Favorite Songs'];
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: playlistNamesValue.length,
                          itemBuilder: (context, index) {
                            final String name =
                                playlistNamesValue[index].toString();
                            final String showName = playlistDetails
                                    .containsKey(name)
                                ? playlistDetails[name]['name']?.toString() ??
                                    name
                                : name;
                            return ListTile(
                              leading: (playlistDetails[name] == null ||
                                      playlistDetails[name]['imagesList'] ==
                                          null ||
                                      (playlistDetails[name]['imagesList']
                                              as List)
                                          .isEmpty)
                                  ? Card(
                                      elevation: 5,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: name == 'Favorite Songs'
                                            ? const Image(
                                                image: AssetImage(
                                                  'assets/cover.jpg',
                                                ),
                                              )
                                            : const Image(
                                                image: AssetImage(
                                                  'assets/album.png',
                                                ),
                                              ),
                                      ),
                                    )
                                  : Collage(
                                      imageList: playlistDetails[name]
                                          ['imagesList'] as List,
                                      showGrid: true,
                                      placeholderImage: 'assets/cover.jpg',
                                    ),
                              title: Text(
                                showName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: playlistDetails[name] == null ||
                                      playlistDetails[name]['count'] == null ||
                                      playlistDetails[name]['count'] == 0
                                  ? null
                                  : Text(
                                      '${playlistDetails[name]['count']} ${AppLocalizations.of(context)!.songs}',
                                    ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15.0),
                                  ),
                                ),
                                onSelected: (int? value) async {
                                  if (value == 1) {
                                    exportPlaylist(
                                      context,
                                      name,
                                      playlistDetails.containsKey(name)
                                          ? playlistDetails[name]['name']
                                                  ?.toString() ??
                                              name
                                          : name,
                                    );
                                  }
                                  if (value == 2) {
                                    sharePlaylist(
                                      context,
                                      name,
                                      playlistDetails.containsKey(name)
                                          ? playlistDetails[name]['name']
                                                  ?.toString() ??
                                              name
                                          : name,
                                    );
                                  }
                                  if (value == 0) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      '${AppLocalizations.of(context)!.deleted} $showName',
                                    );
                                    playlistDetails.remove(name);
                                    await settingsBox.put(
                                      'playlistDetails',
                                      playlistDetails,
                                    );
                                    await playlistNames.removeAt(index);
                                    await settingsBox.put(
                                      'playlistNames',
                                      playlistNames,
                                    );
                                    await Hive.openBox(name);
                                    await Hive.box(name).deleteFromDisk();
                                  }
                                  if (value == 3) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        final _controller =
                                            TextEditingController(
                                          text: showName,
                                        );
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15.0),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!
                                                        .rename,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              TextField(
                                                autofocus: true,
                                                textAlignVertical:
                                                    TextAlignVertical.bottom,
                                                controller: _controller,
                                                onSubmitted: (value) async {
                                                  Navigator.pop(context);
                                                  playlistDetails[name] == null
                                                      ? playlistDetails.addAll({
                                                          name: {
                                                            'name': value.trim()
                                                          }
                                                        })
                                                      : playlistDetails[name]
                                                          .addAll({
                                                          'name': value.trim()
                                                        });

                                                  await settingsBox.put(
                                                    'playlistDetails',
                                                    playlistDetails,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Theme.of(context)
                                                    .iconTheme
                                                    .color,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .cancel,
                                              ),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Colors.white,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                playlistDetails[name] == null
                                                    ? playlistDetails.addAll({
                                                        name: {
                                                          'name': _controller
                                                              .text
                                                              .trim()
                                                        }
                                                      })
                                                    : playlistDetails[name]
                                                        .addAll({
                                                        'name': _controller.text
                                                            .trim()
                                                      });

                                                await settingsBox.put(
                                                  'playlistDetails',
                                                  playlistDetails,
                                                );
                                              },
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!
                                                    .ok,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                              .colorScheme
                                                              .secondary ==
                                                          Colors.white
                                                      ? Colors.black
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (name != 'Favorite Songs')
                                    PopupMenuItem(
                                      value: 3,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit_rounded),
                                          const SizedBox(width: 10.0),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .rename,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (name != 'Favorite Songs')
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_rounded),
                                          const SizedBox(width: 10.0),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .delete,
                                          ),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        const Icon(MdiIcons.export),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          AppLocalizations.of(context)!.export,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        const Icon(MdiIcons.share),
                                        const SizedBox(width: 10.0),
                                        Text(
                                          AppLocalizations.of(context)!.share,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Hive.openBox(name);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LikedSongs(
                                      playlistName: name,
                                      showName:
                                          playlistDetails.containsKey(name)
                                              ? playlistDetails[name]['name']
                                                      ?.toString() ??
                                                  name
                                              : name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
