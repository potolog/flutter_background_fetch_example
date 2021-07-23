import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_fetch_example/services/notificationService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';

const EVENTS_KEY = "fetch_events";


/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var taskId = task.taskId;
  var timeout = task.timeout;
  if (timeout) {
    print("[BackgroundFetch] Headless task timed-out 백그라운드 타스크 타임아웃 : $taskId, ${DateTime.now()}");
    BackgroundFetch.finish(taskId);
    return;
  }

  print("[BackgroundFetch] Headless event received 백그라운드 이벤트 수신 : $taskId, ${DateTime.now()}");

  var timestamp = DateTime.now();

  var prefs = await SharedPreferences.getInstance();

  // Read fetch_events from SharedPreferences
  var events = <String>[];
  var json = prefs.getString(EVENTS_KEY);
  if (json != null) {
    events = jsonDecode(json).cast<String>();
  }

  // Add new event. 신규 이벤트 추가
  events.insert(0, "$taskId@$timestamp [Headless]");

  // Persist fetch events in SharedPreferences
  prefs.setString(EVENTS_KEY, jsonEncode(events));

  if (taskId == 'flutter_background_fetch') {
    /* DISABLED:  uncomment to fire a scheduleTask in headlessTask.
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000,
        periodic: false,
        forceAlarmManager: false,
        stopOnTerminate: false,
        enableHeadless: true
    ));
     */
  }
  BackgroundFetch.finish(taskId);
}

void main() {
  // Enable integration testing with the Flutter Driver extension.
  // See https://flutter.io/testing/ for more info.
  runApp(MyApp());

  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _enabled = true;
  int _status = 0;
  List<String> _events = [];
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    // notification 설정
    if (true) {
      // 안드로이드 설정를 위한 Notification을 설정한 것입니다.
      // 앱 아이콘으로 설정을 바꾸어 줄수 있고 현재 @mipmap/ic_launcher는 flutter 기본 아이콘을 사용하는 것입니다.
      var androidSetting = AndroidInitializationSettings('@mipmap/ic_launcher');

      // ios 알림 설정 : 소리, 뱃지 등을 설정하여 줄수가 있습니다.
      var iosSetting = IOSInitializationSettings();

      // android 와 ios 설정을 통합한다.
      var initializationSettings = InitializationSettings(
          android: androidSetting, iOS: iosSetting);

      // _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,

        // 알림을 눌렀을때 어플에서 실행되는 행동을 설정하는 부분입니다.
        // 비어 있으면 아무런 액션을 하지 않는다.
        //  onSelectNotification: onSelectNotification1(),
        //   onSelectNotification: (String? payload) async {
        //     if (payload != null) {
        //       debugPrint('notification payload: $payload');
        //       showDialog(
        //           context: context,
        //           builder: (_) => AlertDialog(
        //             title: Text('Notification Payload'),
        //             content: Text('Payload: ${payload}'),
        //           )
        //       );
        //     }
        //   }
      );
    }

    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Load persisted fetch events from SharedPreferences
    var prefs = await SharedPreferences.getInstance();
    var json = prefs.getString(EVENTS_KEY);
    if (json != null) {
      setState(() {
        _events = jsonDecode(json).cast<String>();
      });
    }

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(BackgroundFetchConfig(
        // minimumFetchInterval: 15,
        minimumFetchInterval: 1,
        forceAlarmManager: false,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE,
      ), _onBackgroundFetch, _onBackgroundFetchTimeout);
      print('[BackgroundFetch] configure success 설정 성공 : $status, ${DateTime.now()}');
      setState(() {
        _status = status;
      });

      // Schedule a "one-shot" custom-task in 10000ms.
      // These are fairly reliable on Android (particularly with forceAlarmManager) but not iOS,
      // where device must be powered (and delay will be throttled by the OS).
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.transistorsoft.customtask",
          delay: 10000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true
      ));

      // com.x3800.visitor.task 등록
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.x3800.visitor.task",
          delay: 1000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true
      ));

      // com.x3800.visitor.calltask 등록
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.x3800.visitor.calltask",
          delay: 1000,
          periodic: false,
          requiredNetworkType: NetworkType.ANY,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresNetworkConnectivity: true,
      ));

    } catch(e) {
      print("[BackgroundFetch] configure ERROR: $e, ${DateTime.now()}");
      setState(() {
        _status = e.toString() as int;
      });
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  // 백그라운드 이벤트가 발생했을 때의 처리
  void _onBackgroundFetch(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime timestamp = new DateTime.now();
    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
    print("[BackgroundFetch] 이벤트 수신: $taskId, ${DateTime.now()}");
    setState(() {
      _events.insert(0, "$taskId@${timestamp.toString()}");
    });

    // Persist fetch events in SharedPreferences
    prefs.setString(EVENTS_KEY, jsonEncode(_events));

    if (taskId == "flutter_background_fetch") {
      // Schedule a one-shot task when fetch event received (for testing).
      /*
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.transistorsoft.customtask",
          delay: 5000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresNetworkConnectivity: true,
          requiresCharging: true
      ));
       */
    }
    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);

    NotificationService.initialize();
    NotificationService.instantNotification('taskId: $taskId');
  }

  /// This event fires shortly before your task is about to timeout.  You must finish any outstanding work and call BackgroundFetch.finish(taskId).
  void _onBackgroundFetchTimeout(String taskId) {
    print("[BackgroundFetch] TIMEOUT: $taskId, ${DateTime.now()}");
    BackgroundFetch.finish(taskId);
  }

  // 백그라운드 패치 실행 여부 설정
  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success 시작 성공 : $status, ${DateTime.now()}');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e, ${DateTime.now()}');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success 정지 성공 : $status, ${DateTime.now()}');
      });
    }
  }

  // 백그라운드 상태 확인
  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status 상태 : $status, ${DateTime.now()}');
    setState(() {
      _status = status;
    });

    // Notification 알림
    NotificationService.initialize();
    NotificationService.instantNotification('백그라운드 상태 확인');
  }

  // 이벤트 이력 삭제
  void _onClickClear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(EVENTS_KEY);
    setState(() {
      _events = [];
    });

    // Notification 알림
    NotificationService.initialize();
    NotificationService.instantNotification('이벤트 이력 삭제');
  }

  // 화면 빌드
  @override
  Widget build(BuildContext context) {
    const EMPTY_TEXT = Center(child: Text('Waiting for fetch events.  Simulate one.\n [Android] \$ ./scripts/simulate-fetch\n [iOS] XCode->Debug->Simulate Background Fetch'));

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: const Text('BackgroundFetch Example', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.amberAccent,
            brightness: Brightness.light,
            actions: <Widget>[
              Switch(value: _enabled, onChanged: _onClickEnable),
            ]
        ),
        body: (_events.isEmpty) ? EMPTY_TEXT : Container(
          child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (BuildContext context, int index) {
                List<String> event = _events[index].split("@");
                return InputDecorator(
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
                        labelStyle: TextStyle(color: Colors.blue, fontSize: 20.0),
                        labelText: "[${event[0].toString()}]"
                    ),
                    child: Text(event[1], style: TextStyle(color: Colors.black, fontSize: 16.0))
                );
              }
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Container(
                padding: EdgeInsets.only(left: 5.0, right:5.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ElevatedButton(onPressed: _onClickStatus, child: Text('Status: $_status')),
                      ElevatedButton(onPressed: _onClickClear, child: Text('Clear'))
                    ]
                )
            )
        ),
      ),
    );
  }
}
