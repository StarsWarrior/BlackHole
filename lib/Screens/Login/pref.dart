import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:blackhole/CustomWidgets/gradient_containers.dart';

class PrefScreen extends StatefulWidget {
  const PrefScreen({Key? key}) : super(key: key);

  @override
  _PrefScreenState createState() => _PrefScreenState();
}

class _PrefScreenState extends State<PrefScreen> {
  List<String> languages = [
    'Hindi',
    'English',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Kannada',
    'Bhojpuri',
    'Malayalam',
    'Urdu',
    'Haryanvi',
    'Rajasthani',
    'Odia',
    'Assamese'
  ];
  List<bool> isSelected = [true, false];
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList() as List;
  String region =
      Hive.box('settings').get('region', defaultValue: 'India') as String;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width / 1.85,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  child: const Image(
                    image: AssetImage(
                      'assets/icon-white-trans.png',
                    ),
                  ),
                ),
              ),
              const GradientContainer(
                child: null,
                opacity: true,
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.popAndPushNamed(context, '/');
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: 'Welcome\n',
                                      style: TextStyle(
                                        fontSize: 65,
                                        height: 1.0,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).accentColor,
                                      ),
                                      children: <TextSpan>[
                                        const TextSpan(
                                          text: 'Aboard',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 75,
                                            color: Colors.white,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '!\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 70,
                                            color:
                                                Theme.of(context).accentColor,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'Mind telling us a few things?',
                                          style: TextStyle(
                                            height: 1.5,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                        // TextSpan(
                                        //   text: '?',
                                        //   style: TextStyle(
                                        //     fontWeight: FontWeight.bold,
                                        //     fontSize: 20,
                                        //     color: Theme.of(context).accentColor,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ListTile(
                                  title: const Text(
                                    'Which language songs would you prefer to listen to?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.only(
                                        top: 5, bottom: 5, left: 10, right: 10),
                                    height: 57.0,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.grey[900],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5.0,
                                          offset: Offset(0.0, 3.0),
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        preferredLanguage.isEmpty
                                            ? 'None'
                                            : preferredLanguage.join(', '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  dense: true,
                                  onTap: () {
                                    showModalBottomSheet(
                                        isDismissible: true,
                                        backgroundColor: Colors.transparent,
                                        context: context,
                                        builder: (BuildContext context) {
                                          final List checked =
                                              List.from(preferredLanguage);
                                          return StatefulBuilder(builder:
                                              (BuildContext context,
                                                  StateSetter setStt) {
                                            return BottomGradientContainer(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: ListView.builder(
                                                        physics:
                                                            const BouncingScrollPhysics(),
                                                        shrinkWrap: true,
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                0, 10, 0, 10),
                                                        itemCount:
                                                            languages.length,
                                                        itemBuilder:
                                                            (context, idx) {
                                                          return CheckboxListTile(
                                                            activeColor: Theme
                                                                    .of(context)
                                                                .accentColor,
                                                            value: checked
                                                                .contains(
                                                                    languages[
                                                                        idx]),
                                                            title: Text(
                                                                languages[idx]),
                                                            onChanged:
                                                                (bool? value) {
                                                              value!
                                                                  ? checked.add(
                                                                      languages[
                                                                          idx])
                                                                  : checked.remove(
                                                                      languages[
                                                                          idx]);
                                                              setStt(() {});
                                                            },
                                                          );
                                                        }),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        style: TextButton
                                                            .styleFrom(
                                                          primary:
                                                              Theme.of(context)
                                                                  .accentColor,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        style: TextButton
                                                            .styleFrom(
                                                          primary:
                                                              Theme.of(context)
                                                                  .accentColor,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            preferredLanguage =
                                                                checked;
                                                            Navigator.pop(
                                                                context);
                                                            Hive.box('settings')
                                                                .put(
                                                                    'preferredLanguage',
                                                                    checked);
                                                          });
                                                          if (preferredLanguage
                                                              .isEmpty) {
                                                            ShowSnackBar()
                                                                .showSnackBar(
                                                              context,
                                                              'No Music language selected. Select a language to see songs on Home Screen',
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          'Ok',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          });
                                        });
                                  },
                                ),
                                const SizedBox(
                                  height: 30.0,
                                ),
                                ListTile(
                                    title: const Text(
                                      'For which country would you like to see Spotify Local Charts?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.only(
                                          top: 5,
                                          bottom: 5,
                                          left: 10,
                                          right: 10),
                                      height: 57.0,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Colors.grey[900],
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          region,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ),
                                    dense: true,
                                    onTap: () {
                                      showModalBottomSheet(
                                          isDismissible: true,
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          builder: (BuildContext context) {
                                            final Map<String, String> codes =
                                                CountryCodes().countryCodes;
                                            final List<String> countries =
                                                codes.keys.toList();
                                            return BottomGradientContainer(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              child: ListView.builder(
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  shrinkWrap: true,
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 10, 0, 10),
                                                  itemCount: countries.length,
                                                  itemBuilder: (context, idx) {
                                                    return ListTileTheme(
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                      child: ListTile(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                    .only(
                                                                left: 25.0,
                                                                right: 25.0),
                                                        title: Text(
                                                            countries[idx]),
                                                        trailing: region ==
                                                                countries[idx]
                                                            ? const Icon(Icons
                                                                .check_rounded)
                                                            : const SizedBox(),
                                                        selected: region ==
                                                            countries[idx],
                                                        onTap: () {
                                                          region =
                                                              countries[idx];
                                                          Hive.box('settings')
                                                              .put('region',
                                                                  region);
                                                          Navigator.pop(
                                                              context);
                                                          setState(() {});
                                                        },
                                                      ),
                                                    );
                                                  }),
                                            );
                                          });
                                    }),
                                const SizedBox(
                                  height: 30.0,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.popAndPushNamed(context, '/');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    height: 55.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      // color: Theme.of(context).accentColor,
                                      color: Colors.tealAccent[400],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5.0,
                                          offset: Offset(0.0, 3.0),
                                        )
                                      ],
                                    ),
                                    child: const Center(
                                        child: Text(
                                      'Finish',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.0,
                                      ),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
