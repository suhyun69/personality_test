import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../sub/question_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {

  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  FirebaseDatabase database = FirebaseDatabase.instance;
  late DatabaseReference _testRef;
  late List<String> testList = List.empty(growable: true);

  String welcomeTitle = '';
  bool bannerUse = false;
  int itemHeight = 50;

  @override
  void initState() {
    super.initState();
    remoteConfigInit();
    _testRef = database.ref('test');
  }

  void remoteConfigInit() async {
    await remoteConfig.fetch();
    await remoteConfig.activate();
    welcomeTitle = remoteConfig.getString('welcome');
    bannerUse = remoteConfig.getBool('banner');
    itemHeight = remoteConfig.getInt('item_height');
  }

  // JSON 파일을 비동기로 로드하는 함수
  Future<List<String>> loadAsset() async {
    try {
      final snapshot = await _testRef.get();
      snapshot.children.forEach((element) {
        testList.add(element.value as String);
      });
      return testList;
    } catch (e) {
      print('Failed to load data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bannerUse
        ? AppBar(
          title: Text(remoteConfig.getString('welcome'))
        )
        : null,
      body: FutureBuilder<List<String>> (
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
                // Map<String, dynamic> list = jsonDecode(snapshot.data!);
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> item = jsonDecode(snapshot.data![index], );
                    return InkWell(
                      child: SizedBox(
                        height: remoteConfig.getInt('item_height').toDouble(),
                        child: Card(
                          color: Colors.amber,
                          child: Text(item['title'].toString())
                        )
                      ),
                      onTap: () async {
                        await FirebaseAnalytics.instance.logEvent(
                          name: 'test_click',
                          parameters: {
                            'test_name': item['title'].toString()
                          }
                        ).then((result) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) {
                              return QuestionPage(question: item);
                            }
                          ));
                        });
                      },
                    );
                  }
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
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          FirebaseDatabase database = FirebaseDatabase.instance;
          DatabaseReference _testRef = database.ref('test');
          _testRef.push().set("""{
            "title": "당신이 좋아하는 애완동물은",
            "question": "당신이 무인도에 도착했는데 마침 떠내려온 상자를 열었을때 보이는 이것은",
            "selects": [
              "생존키트",
              "휴대폰",
              "텐트",
              "무인도에서 살아남기"
            ],
            "answer": [
              "당신은 현실주의 동물은 안키운다!!",
              "당신은 늘 함께 있는 걸 좋아하는 강아지가 딱입니다",
              "당신은 같은 공간을 공유하는 고양이",
              "당신은 낭만을 좋아하는 앵무새"
            ]
          }""");
          _testRef.push().set("""{
            "title": "5초 MBTI I/E 편",
            "question": "친구와 함께 간 미술관 당신이라면",
            "selects": [
              "말이 많아짐",
              "생각이 많아짐"
            ],
            "answer": [
              "당신의 성향은 E",
              "당신의 성향은 I"
            ]
          }""");
          _testRef.push().set("""{
            "title": "당신은 어떤 사랑을 하고 싶나요",
            "question": "목욕을 할때 가장 먼저 비누칠을 하는 곳은",
            "selects": [
              "머리",
              "상체",
              "하체"
            ],
            "answer": [
              "당신은 자만추를 추천해요",
              "당신은 소개팅을 통한 새로운 사람의 소개를 좋아합니다",
              "당신은 길가다가 우연히 지나친 그런 인연을 좋아합니다"
            ]
          }""");
        },
      ),
    );
  }
}