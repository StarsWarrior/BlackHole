import 'package:blackhole/Helpers/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PlayerGradientSelection extends StatefulWidget {
  const PlayerGradientSelection({Key? key}) : super(key: key);

  @override
  State<PlayerGradientSelection> createState() =>
      _PlayerGradientSelectionState();
}

class _PlayerGradientSelectionState extends State<PlayerGradientSelection> {
  final List<String> types = ['simple', 'halfDark', 'halfLight', 'full'];
  final List<Color?> gradientColor = [Colors.lightGreen, Colors.teal];
  final MyTheme currentTheme = GetIt.I<MyTheme>();
  String gradientType = Hive.box('settings')
      .get('gradientType', defaultValue: 'halfDark')
      .toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!
              .playerScreenBackground,
        ),
      ),
      body: SafeArea(
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          physics: const BouncingScrollPhysics(),
          childAspectRatio: 0.6,
          children: types
              .map(
                (type) => GestureDetector(
                  onTap: () {
                    setState(() {
                      gradientType = type;
                      Hive.box('settings').put('gradientType', type);
                    });
                  },
                  child: SizedBox(
                    child: Stack(
                      children: [
                        Card(
                          elevation: 5,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: gradientType == type ? 2.0 : 0.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: type == 'simple'
                                    ? Alignment.topLeft
                                    : Alignment.topCenter,
                                end: type == 'simple'
                                    ? Alignment.bottomRight
                                    : type == 'full'
                                        ? Alignment.bottomCenter
                                        : Alignment.center,
                                colors: type == 'simple'
                                    ? Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? currentTheme.getBackGradient()
                                        : [
                                            const Color(0xfff5f9ff),
                                            Colors.white,
                                          ]
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? [
                                            if (type == 'halfDark')
                                              gradientColor[1] ??
                                                  Colors.grey[900]!
                                            else
                                              gradientColor[0] ??
                                                  Colors.grey[900]!,
                                            if (type == 'halfLight' ||
                                                type == 'halfDark')
                                              Colors.black
                                            else
                                              gradientColor[1] ?? Colors.black
                                          ]
                                        : [
                                            gradientColor[0] ??
                                                const Color(0xfff5f9ff),
                                            Colors.white,
                                          ],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            const Spacer(
                              flex: 3,
                            ),
                            Center(
                              child: Card(
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: FittedBox(
                                  child: SizedBox.square(
                                    dimension:
                                        MediaQuery.of(context).size.width / 5,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(
                              flex: 3,
                            ),
                            Center(
                              child: Card(
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: FittedBox(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 5,
                                    height:
                                        MediaQuery.of(context).size.width / 25,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Card(
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: FittedBox(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 5,
                                    height:
                                        MediaQuery.of(context).size.width / 25,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(
                              flex: 3,
                            ),
                          ],
                        ),
                        if (gradientType == type)
                          const Center(child: Icon(Icons.check_rounded)),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
