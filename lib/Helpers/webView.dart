import 'package:blackhole/APIs/spotifyApi.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:async';

class SpotifyWebView extends StatefulWidget {
  @override
  _SpotifyWebViewState createState() => _SpotifyWebViewState();
}

class _SpotifyWebViewState extends State<SpotifyWebView> {
  bool showLoading = true;
  BuildContext mContext;
  WebViewController controller;
  String code;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Login to Spotify"),
        ),
        body: Stack(
          children: [
            WebView(
                initialUrl: "${SpotifyApi().requestAuthorization()}",
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController con) {
                  setState(() {
                    controller = con;
                  });
                },
                onProgress: (progress) {
                  if (progress > 70 && showLoading) {
                    setState(() {
                      showLoading = false;
                    });
                  }
                },
                onPageFinished: (url) {
                  setState(() {
                    showLoading = false;
                  });
                  if (url.contains("code=")) {
                    code = getCodeParameter(url);
                    Future.delayed(Duration(seconds: 2));
                    print("code is...");
                    print(code);
                    Navigator.pop(context, code);
                  }
                }),
            if (showLoading)
              Container(
                child: Center(
                  child: Container(
                      height: MediaQuery.of(context).size.width / 6,
                      width: MediaQuery.of(context).size.width / 6,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).accentColor),
                        strokeWidth: 5,
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String getCodeParameter(String url) {
    return Uri.dataFromString(url).queryParameters['code'];
  }
}
