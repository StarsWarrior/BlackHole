import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  double appVersion = 1.4;
  String gender = "male";
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  final dbRef = FirebaseDatabase.instance.reference().child("Users");

  Future _sendAnalytics(name, gender) async {
    // final FirebaseAnalytics analytics = FirebaseAnalytics();

    DatabaseReference pushedPostRef = dbRef.push();
    String postId = pushedPostRef.key;
    pushedPostRef.set({
      "name": name,
      "email": "",
      "DOB": "",
      "gender": gender,
      "country": "",
      "streamingQuality": "",
      "downloadQuality": "",
      "version": appVersion,
      "darkMode": "",
      "themeColor": "",
      "colorHue": "",
      "lastLogin": "",
      "accountCreatedOn": DateTime.now()
          .toUtc()
          .add(Duration(hours: 5, minutes: 30))
          .toString()
          .split('.')
          .first,
      "deviceInfo": "",
      "preferredLanguage": ["Hindi"],
    });
    Hive.box('settings').put('userID', postId);

    analytics.logEvent(
      name: 'NewUser',
      parameters: <String, dynamic>{
        'Name': name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Firebase.initializeApp();
    // _auth = FirebaseAuth.instance;
    final controller = TextEditingController();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.grey[850],
                  Colors.grey[900],
                  Colors.black,
                ]
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).size.width / 2,
            top: MediaQuery.of(context).size.width / 5,
            child: Image(
              image: AssetImage(
                'assets/icon-white-trans.png',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                // stops: [0, 0.2, 0.8, 1],
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Colors.grey[850].withOpacity(0.8),
                        Colors.grey[900].withOpacity(0.9),
                        Colors.black.withOpacity(1),
                      ]
                    : [
                        Colors.white,
                        Theme.of(context).canvasColor,
                      ],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: Image(image: AssetImage('assets/hello.png')),
                    ),
                    // SizedBox(
                    //   height: 1,
                    // ),
                    Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "I'm ",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'BlackHole',
                                style: TextStyle(
                                  // color: Theme.of(context).accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'and ',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'YOU?',
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 57,
                                  ),
                                )
                              ]),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                            children: [
                              Text("I'm a",
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                        Colors.tealAccent[400],
                                        BlendMode.srcIn),
                                    child: Image(
                                        image: AssetImage(gender == 'female'
                                            ? 'assets/female.png'
                                            : 'assets/male.png')),
                                  ),
                                  onTap: () {
                                    gender == 'female'
                                        ? gender = 'male'
                                        : gender = 'female';
                                    Hive.box('settings').put('gender', gender);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Container(
                            padding: EdgeInsets.only(
                                top: 5, bottom: 5, left: 10, right: 10),
                            // margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.0,
                                  offset: Offset(0.0,
                                      3.0), // shadow direction: bottom right
                                )
                              ],
                            ),
                            child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.person),
                                  border: InputBorder.none,
                                  hintText: "Your Name",
                                ),
                                onSubmitted: (value) {
                                  if (value == '') {
                                    Hive.box('settings').put('name', 'Guest');
                                    _sendAnalytics('Guest', gender);
                                  } else {
                                    Hive.box('settings').put('name', value);
                                    _sendAnalytics(value, gender);
                                  }
                                  Navigator.popAndPushNamed(context, '/');
                                }),
                          ),
                        ),
                        // SizedBox(
                        //   height: 15,
                        // ),

                        // TextButton(
                        //     style: TextButton.styleFrom(
                        //       primary: Colors.white,
                        //       backgroundColor: Theme.of(context).accentColor,
                        //     ),
                        //     onPressed: () {
                        //       Hive.box('settings')
                        //           .put('name', controller.text);
                        //       Navigator.pushNamed(context, '/');
                        //     },
                        //     child: Text('Submit')),
                      ],
                    ),
                    // SizedBox(
                    //   height: 1,
                    // ),
                  ],
                ),
              ),
            ),

            // TextButton(
            //   child: Text('Signin with Google',
            //       style: TextStyle(color: Colors.white)),
            //   onPressed: () async {
            //     dynamic result = await signIn();
            //     if (result != null) {
            //       print(result);
            //       Hive.box('settings').put('signin', true);
            //     } else {
            //       print('Failed to Signin');
            //     }
            //     // Navigator.pushNamed(context, '/');
            //   },
            // ),
            // TextButton(onPressed: null, child: Text('Signout'))
          ),
        ],
      ),
    );
  }
}
