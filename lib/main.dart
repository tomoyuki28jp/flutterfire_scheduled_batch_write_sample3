import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sample3/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Text('error');
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snap.data?.uid == null) {
          return AuthPage();
        } else {
          return const ActivityTracker();
        }
      },
    ));
  }
}

CollectionReference<MinutelyActivity> _minutelyActivitiesRef(String uid) =>
    FirebaseFirestore.instance
        .collection('users/$uid/minutely_desktop_activities')
        .withConverter<MinutelyActivity>(
            fromFirestore: (snapshots, _) =>
                MinutelyActivity.fromJson(snapshots.data()!),
            toFirestore: (model, _) => model.toJson()
              ..addAll(
                  <String, Object>{'created': FieldValue.serverTimestamp()}));

class MinutelyActivity {
  const MinutelyActivity(
      {required this.beginningOfMinute, this.activeSeconds = const <int>[]});
  final DateTime beginningOfMinute;
  final List<int> activeSeconds;

  MinutelyActivity.fromJson(Map<String, Object?> json)
      : this(
            beginningOfMinute:
                (json['beginningOfMinute']! as Timestamp).toDate(),
            activeSeconds: (json['activeSeconds']! as List<int>));

  Map<String, Object?> toJson() {
    return {
      'beginningOfMinute': Timestamp.fromDate(beginningOfMinute),
      'activeSeconds': activeSeconds
    };
  }
}

class ActivityTracker extends StatefulWidget {
  const ActivityTracker({Key? key}) : super(key: key);

  @override
  _ActivityTrackerState createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  Map<DateTime, MinutelyActivity> _activities = {};
  late Timer _timer;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _update());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static DateTime _beginningOfMinute(DateTime date) =>
      DateTime(date.year, date.month, date.day, date.hour, date.minute);

  Future<void> _update() async {
    final now = DateTime.now();
    final beginningOfMinute = _beginningOfMinute(now);
    setState(() {
      if (_activities[beginningOfMinute] == null) {
        _activities[beginningOfMinute] = MinutelyActivity(
            beginningOfMinute: beginningOfMinute, activeSeconds: [now.second]);
      } else {
        _activities[beginningOfMinute]!.activeSeconds.add(now.second);
      }
    });

    if (_saving) {
      return;
    }

    _saving = true;
    try {
      final col =
          _minutelyActivitiesRef(FirebaseAuth.instance.currentUser!.uid);
      _activities.forEach((min, activity) {
        final id = min.toUtc().toIso8601String();
        final doc = col.doc(id);
        if (min.isBefore(beginningOfMinute)) {
          debugPrint('add min activity: $min');
          doc.set(activity).then((_) {
            setState(() {
              _activities.remove(min);
              _activities = _activities;
            });
          }).catchError((e) async {
            // workaround: created doc keep throwing a permission-denied error
            if ((await doc.get()).exists) {
              debugPrint('workaround');
              setState(() {
                _activities.remove(min);
                _activities = _activities;
              });
            } else {
              print(e);
            }
          });
        }
      });
    } on Exception catch (e) {
      print(e);
      rethrow;
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: const Text('Tracking...'));
  }
}
