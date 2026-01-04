// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
// Roulette source: https://pub.dev/packages/roulette

// In progress: Make the function for adding new lists/items.
// In progress: Add the function of recording restaurants in the diary.
// In progress: Change the app icon and name.
// In progress: 用來決定"等下做什麼"也很好用，思考一下怎麼整合這兩個功能。

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roulette/roulette.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data

enum RGB {R,G,B}
ValueNotifier<String> selectedList = ValueNotifier('午晚餐');
final List<String> localListOrder = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize
  await Hive.openBox('settings');
  await Hive.openBox<List>('localLists');
  await initializeDefaultLists();
  runApp(MyApp());
}

// Initialize
Future<bool> isFirstLaunch() async {
  return !(Hive.box('settings').get('isInitialized', defaultValue: false) as bool);
}

Future<void> setInitialized() async {
  await Hive.box('settings').put('isInitialized', true);
}

Future<void> initializeDefaultLists() async {
  final box = Hive.box<List>('localLists');
  // Initial lists
  if (box.get('早餐', defaultValue: [])!.isEmpty) {
    await box.put('早餐',
    ['Meal 1',
     'Meal 2',
     'Meal 3',
     'Meal 4',
     'Meal 5',]);
  }
  if (box.get('午晚餐', defaultValue: [])!.isEmpty) {
    await box.put('午晚餐',
    ['Meal 1',
     'Meal 2',
     'Meal 3',
     'Meal 4',
     'Meal 5',]);
  }
  if (box.get('List 3', defaultValue: [])!.isEmpty) {
    await box.put('List 3',
    ['Meal 1',
     'Meal 2',
     'Meal 3',
     'Meal 4',
     'Meal 5',]);
  }

  for(int i=box.length-1;i>=0;i--){ localListOrder.add(box.keyAt(i)); }

  // Flagging
  if (await isFirstLaunch()) { await setInitialized(); }
}

// Local save/load
Future<void> saveAllLists(Map<String, List<String>> lists) async {
  final box = Hive.box<List>('localLists');
  print('Saving lists...');
  //await box.clear(); // Optional: Fully replace existing data
  for (var entry in lists.entries) {
    await box.put(entry.key, entry.value);
  }
  print('All lists saved successfully!');
}

Map<String, List<String>> loadAllLists() {
  final box = Hive.box<List>('localLists');
  print('Loading lists...');
  return {
    for (var key in box.keys)
      key.toString(): box.get(key, defaultValue: [])!.cast<String>(),
  };
}

// List editting
void newList(String name) {
  final box = Hive.box<List>('localLists');
  if (!box.containsKey(name)) { box.put(name, []); }
  localListOrder.clear();
  for(int i=0;i<box.length;i++){ localListOrder.add(box.keyAt(i)); }
}

void removeList(String name) {
  final box = Hive.box<List>('localLists');
  if (box.containsKey(name)) { box.delete(name); }
  localListOrder.clear();
  for(int i=0;i<box.length;i++){ localListOrder.add(box.keyAt(i)); }
}

void newItem(String listName,String itemName) {
  final box = Hive.box<List>('localLists');
  final list = box.get(listName, defaultValue: [])!.cast<String>();
  // ! = Force to treat data as non-null
  // cast<String>() = Force assign every data value as string types.
  list.add(itemName);
  box.put(listName, list);
}

void removeItem(String listName,String itemName) {
  final box = Hive.box<List>('localLists');
  final list = box.get(listName, defaultValue: [])!.cast<String>();
  list.remove(itemName);
  box.put(listName, list);
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

class MyRoulette extends StatelessWidget {
  const MyRoulette({
    super.key,
    required this.controller,
    required this.group,
  });

  final RouletteGroup group;
  final RouletteController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Roulette(
              group: group,
              // Provide controller to update its state
              controller: controller,
              // Configure roulette's appearance
              style: const RouletteStyle(
                dividerThickness: 2.5,
                dividerColor: Colors.white,
                centerStickSizePercent: 0.08,
                centerStickerColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Roulette'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Diary'),
        ],
      ),
    );
  }
}

class RoulettePage extends StatefulWidget {
  @override
  RoulettePageState createState() => RoulettePageState();
}

class RoulettePageState extends State<RoulettePage>{
  static final _random = Random();
  final _controller = RouletteController();
  final bool _clockwise = true;

  // In progress: Make it possible to switch between lists.
  List<String> get rouletteList => Hive.box<List>('localLists').get(selectedList.value, defaultValue: [])!.cast<String>();

  @override
  Widget build(BuildContext context) {
    
    if (rouletteList.isEmpty) {
      return Scaffold(
        appBar: AppBar( title: Text('等下吃什麼?'), ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.pink.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () { // Edit list button
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => EditListPage(),
                          ),
                        );
                      },
                      child: const Text('編輯清單'),
                    ),
                    const SizedBox(height: 100),
                    const Center(child: Text('清單是空的，請先編輯清單')),
                    const SizedBox(height: 50),
                    FilledButton( // Roll button disabled
                      onPressed: null,
                      child: const Text('抽!'),
                    ),
                    FilledButton( // Cancel button
                      onPressed: () { _controller.stop(); },
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Color control
    final List<Color> colors = <Color>[];
    final int value = rouletteList.length*100;
    final List<int> sat = [150,1,255];
    final List<int> cRange = [255,0,100];
    
    for(int i=0;i<rouletteList.length;i++){
      int color(int x) => ((sin(cRange[x]/rouletteList.length*i)*value).round()+255-cRange[x])%sat[x];
      colors.add(Color.fromARGB(255, color(0), color(1), color(2)).withAlpha(70),);
    }

    // Generating roulette
    late final group = RouletteGroup.uniform(
      rouletteList.length,
      colorBuilder: (index) => colors[index%colors.length],
      textBuilder: (index) => rouletteList[index],
      textStyleBuilder: (index) {
        return const TextStyle(color: Colors.black, fontWeight: FontWeight.bold);
      },
    );

    return Scaffold(
      appBar: AppBar( title: Text('等下吃什麼?'), ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.pink.withOpacity(0.1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () { // Edit list button
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => EditListPage(),
                        ),
                      );
                    },
                    child: const Text('編輯清單'),
                  ),
                  Stack( // Roulette
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: MyRoulette(
                          group: group,
                          controller: _controller,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 50,
                        color: const Color.fromARGB(255, 255, 139, 101),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  FilledButton( // Roll button
                    onPressed: () async {
                      final int resultInt = _random.nextInt(rouletteList.length);
                      final completed = await _controller.rollTo(
                        resultInt,
                        clockwise: _clockwise,
                        offset: _random.nextDouble(),
                      );
          
                      if (completed) {
                        String result = rouletteList[resultInt];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已取消')),
                        );
                      }
                    },
                    child: const Text('抽!'),
                  ),
                  FilledButton( // Cancel button
                    onPressed: () { _controller.stop(); },
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

// Edit
class EditListPage extends StatefulWidget {
  @override
  _EditListPageState createState() => _EditListPageState();
}

class _EditListPageState extends State<EditListPage> {
  final box = Hive.box<List>('localLists');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text('編輯清單'), ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<List> box, child) {
          return ReorderableListView.builder( // List
            padding: const EdgeInsets.all(12.0),
            itemCount: box.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final key = localListOrder.removeAt(oldIndex);
              localListOrder.insert(newIndex, key);
            },
            itemBuilder: (context, index) {
              return ListEditBox(key: ValueKey(localListOrder[index]), curList: localListOrder[index]);
            },
          );
        },
      ),
    );
  }
}

class ListEditBox extends StatelessWidget {
  final String curList;
  const ListEditBox({super.key, required this.curList});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder( // Refresh
        valueListenable: selectedList,
        builder: (context, value, child) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: (curList==selectedList.value) ? const Color.fromARGB(255, 191, 177, 229) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ReorderableDragStartListener(
                  index: Hive.box<List>('localLists').keys.toList().indexOf(curList),
                  child: IconButton( // Move layers
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                  ),
                ),
                Expanded(
                  child: Text( // List name
                    curList,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  ),
                ),
                IconButton( // Selection
                  onPressed: () { selectedList.value = curList; },
                  icon: (curList==selectedList.value) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                ),
                IconButton( // Edit
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditItemPage(listName:curList),
                        ),
                      );
                    },
                  icon: const Icon(Icons.edit),
                ),
                IconButton( // Delete
                  onPressed: () { removeList(curList); }, icon: const Icon(Icons.delete),
                ),
              ]
            ),
          );
        },
      );
  }
}

class NameEdit extends StatefulWidget {
  final String prevName;
  const NameEdit({super.key, required this.prevName});

  @override
  _NameEditState createState() => _NameEditState();
}

class _NameEditState extends State<NameEdit>{
  final _newName = GlobalKey<FormState>();
  final nameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _newName,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            // The validator receives the text that the user has entered.
            validator: (value) { return null; },
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              labelText: widget.prevName,
            ),
          ),
          FilledButton(
            onPressed: () {
              // Validate returns true if the form is valid, or false otherwise.
              Navigator.pop(context,nameController.text);
            },
            child: const Text('確定'),
          ),
        ]
      ),
    );
  }
}

class EditItemPage extends StatefulWidget {
  final String listName;
  const EditItemPage({super.key, required this.listName});

  @override
  _EditItemPageState createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final box = Hive.box<List>('localLists');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          IconButton( // Edit
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NameEdit(prevName:widget.listName),
                  ),
                );
              },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: ValueNotifier(box.get(widget.listName, defaultValue: [])!.cast<String>()),
        builder: (context, List<String> itemList, child) {
          return ReorderableListView.builder( // List
            padding: const EdgeInsets.all(12.0),
            itemCount: itemList.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final key = itemList.removeAt(oldIndex);
              itemList.insert(newIndex, key);
            },
            itemBuilder: (context, index) {
              return ItemEditBox(key: ValueKey(itemList[index]), curList: widget.listName, curItem: itemList[index]);
            },
          );
        },
      ),
    );
  }
}

class ItemEditBox extends StatefulWidget {
  final String curList;
  final String curItem;
  ItemEditBox({super.key, required this.curList, required this.curItem});

  @override
  _ItemEditBoxState createState() => _ItemEditBoxState();
}

class _ItemEditBoxState extends State<ItemEditBox>{

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ReorderableDragStartListener(
            index: Hive.box<List>('localLists').get(widget.curList, defaultValue: [])!.cast<String>().indexOf(widget.curItem),
            child: IconButton( // Move layers
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ),
          Expanded(
            child: Text( // List name
              widget.curItem,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black
              ),
            ),
          ),
          IconButton( // Edit // In progress...
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => NameEdit(prevName:widget.curItem),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton( // Delete // In progress...
            onPressed: () { removeItem(widget.curList, widget.curItem); }, icon: const Icon(Icons.delete),
          ),
        ]
      ),
    );
  }
}

class DiaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar( title: const Text('用餐日記'), ),
      body: Column(
        // In progress...
      ),
    );
  }
}