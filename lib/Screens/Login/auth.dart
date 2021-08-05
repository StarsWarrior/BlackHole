import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Helpers/supabase.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info/package_info.dart';
import 'package:uuid/uuid.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String appVersion;
  TextEditingController controller;
  Uuid uuid = Uuid();

  @override
  void initState() {
    main();
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void main() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
  }

  Future _addUserData(String name) async {
    int status;
    await Hive.box('settings').put('name', name.trim());
    DateTime now = DateTime.now();
    List createDate =
        now.toUtc().add(Duration(hours: 5, minutes: 30)).toString().split('.')
          ..removeLast()
          ..join('.');

    String userId = uuid.v1();
    status = await SupaBase().createUser({
      "id": userId,
      "name": name,
      "version": appVersion,
      "accountCreatedOn": "${createDate[0]} IST",
      "timeZone":
          "Zone: ${now.timeZoneName} Offset: ${now.timeZoneOffset.toString().replaceAll('.000000', '')}",
      "lastLogin": "${createDate[0]} IST",
    });

    while (status == null || status == 409) {
      userId = uuid.v1();
      status = await SupaBase().createUser({
        "id": userId,
        "name": name,
        "version": appVersion,
        "accountCreatedOn": "${createDate[0]} IST",
        "timeZone":
            "Zone: ${now.timeZoneName} Offset: ${now.timeZoneOffset.toString().replaceAll('.000000', '')}",
        "lastLogin": "${createDate[0]} IST",
      });
    }
    await Hive.box('settings').put('userId', userId);
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
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
          GradientContainer(
            child: null,
            opacity: true,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                                top: 5, bottom: 5, left: 10, right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.0,
                                  offset: Offset(0.0, 3.0),
                                )
                              ],
                            ),
                            child: TextField(
                                controller: controller,
                                textAlignVertical: TextAlignVertical.center,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                keyboardType: TextInputType.name,
                                decoration: InputDecoration(
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 1.5, color: Colors.transparent),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Theme.of(context).accentColor,
                                  ),
                                  border: InputBorder.none,
                                  hintText: "Your Name",
                                  hintStyle: TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                                onSubmitted: (String value) {
                                  if (value == '') {
                                    _addUserData('Guest');
                                  } else {
                                    _addUserData(value.trim());
                                  }
                                  Hive.box('settings').put('auth', 'done');
                                  Navigator.popAndPushNamed(context, '/');
                                }),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 8.0, right: 8.0, top: 5.0),
                            child: Text(
                                "Disclaimer: We respect your privacy more than anything else. Only your name, which you will enter here, will be recorded.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.withOpacity(0.7))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
