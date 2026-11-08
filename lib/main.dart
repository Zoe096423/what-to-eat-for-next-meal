// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, must_be_immutable
// Roulette source: https://pub.dev/packages/roulette

// Bugs to be fixed:
//    Somehow the "早餐" list disappeared when I opened the app. Due to localListOrder initializing? How to make list order permenantly stored? Open a new box?
//    Is it normal that when I reinstall the apk, the lists reset? The files has to be stored in cache, right?
//    When adding new food to list via diary, the food name becomes default name (Meal 1)
//    Colors for the roulette looks a little weird?
//    When adding new food to list via diary, some food are simultaneously added to multiple lists.
//    Optimize? The app kinda burns my phone.

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
  await Hive.openBox('settings');
  
  // migration: open untyped so we can inspect raw contents without Hive doing its own casts
  await Hive.openBox('localLists');
  final rawBox = Hive.box('localLists');
  for (var key in rawBox.keys) {
    migration(rawBox, key);
  }
  // after migration the box remains open for normal (untyped) usage
  //Hive.box<List<Item>>('localLists').clear();

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
      title: '等下吃什麼?',
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