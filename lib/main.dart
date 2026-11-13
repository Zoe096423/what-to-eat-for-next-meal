// Roulette source: https://pub.dev/packages/roulette

// Bugs to be fixed:
//    Somehow the "早餐" list resetted when I opened the app. Due to localListOrder initializing? How to make list order permenantly stored? Open a new box?
//    Is it normal that when I reinstall the apk, the lists reset? The files has to be stored in cache, right?
//    When adding new food to list via diary, the food name becomes default name (Meal 1)
//    When adding new food to list via diary, some food are simultaneously added to multiple lists.
//    Optimize? The app kinda burns my phone.
//    When adding, editing, or deleting diary entries, it dooes not refresh immediately despite having setState(){}. 

// Features to be added:
// -> Arrange the diary properly.
//    When finished polling, buttons "好哇" "再抽一次" "算了" pop up. Choosing "好哇" auto adds the food to diary. Choosing "再抽一次" auto filters out the last result (until the app is restarted) and polls again. Choosing "算了" stops the poll.
//    Add the function to filter via tags.
//    Move the button for adding diary to the bottom right as a floating button which position can be changed via long pressing & dragging.
//    Add the function of manually changing the percentage in editItem.

// Packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data

// Files
import 'basic/classes.dart';
import 'basic/functions.dart';
import 'widgets/roulette.dart';
import 'widgets/diary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize
  // Register adapters for custom Hive types
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TagAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ItemAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DiaryAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ItemMenuAdapter());
  await Hive.openBox('settings');
  await Hive.openBox('localLists');
  await Hive.openBox<Diary>('diary');
  await initializeDefaultLists();
  runApp(MyApp());
}

// Main app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  final List<Widget> pages = [ // final -> Add/remove elements (O), reassign (X)
    RoulettePage(),
    DiaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    if(currentIndex >= pages.length) {
      throw UnimplementedError('no widget for $currentIndex');
    }

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() { currentIndex = index; });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.speed), label: 'Roulette'),
          BottomNavigationBarItem(icon: const Icon(Icons.article), label: 'Diary'),
        ],
      ),
    );
  }
}