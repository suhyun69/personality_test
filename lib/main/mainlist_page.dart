import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../sub/question_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {

  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  String welcomeTitle = '';
  bool bannerUse = false;
  int itemHeight = 50;

  @override
  void initState() {
    super.initState();
    remoteConfigInit();
  }

  void remoteConfigInit() async {
    await remoteConfig.fetch();
    await remoteConfig.activate();
    welcomeTitle = remoteConfig.getString('welcome');
    bannerUse = remoteConfig.getBool('banner');
    itemHeight = remoteConfig.getInt('item_height');
  }

  // JSON 파일을 비동기로 로드하는 함수
  Future<String> loadAsset() async {
    return await rootBundle.loadString('res/api/list.json');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bannerUse
        ? AppBar(
          title: Text(remoteConfig.getString('welcome'))
        )
        : null,
      body: FutureBuilder<String> (
        future: loadAsset(),
        builder: (context, snapshot) {
          // 연결 상태에 따라 다른 위젯을 보여 주기
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              // 데이터를 가져오는 동안 CircularProgressIndicator 표시하기
              return const Center(
                child: CircularProgressIndicator(),
              );
            case ConnectionState.done:
              // 데이터 가져오기에 성공했다면
              if (snapshot.hasData) {
                Map<String, dynamic> list = jsonDecode(snapshot.data!);
                return ListView.builder(
                  itemCount: list['count'],
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        try {
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'test_click',
                            parameters: {
                              'test_name': list['questions'][index]['title'].toString(),
                            }
                          );
                          await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) {
                                    return QuestionPage(
                                      question:
                                        list['questions'][index]['file'].toString()
                                    );
                          }));
                        }
                        catch (e) {
                          print('Failed to log event: $e');
                        }
                      },
                      child: SizedBox(
                        height: itemHeight.toDouble(),
                        child: Card(
                          child: Text(
                            list['questions'][index]['title'].toString()
                          )
                        ),
                      )
                    );
                  },
                );
              } else if (snapshot.hasError) {
                // 오류가 발생했다면 오류 메시지 표시하기
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                // 데이터가 없다면 'No Data' 표시
                return const Center(
                  child: Text('No Data'),
                );
              }
            default:
              return const Center(
                child: Text('No Data'),
              );
          }
        }
      )
    );
  }
}