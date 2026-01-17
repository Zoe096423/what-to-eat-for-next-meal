// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, must_be_immutable
// Roulette source: https://pub.dev/packages/roulette

// In progress: Make the diary page functionable.
// In progress: Add the function of manually changing the percentage in editItem.
// In progress: Change the app icon and name.

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
  await Hive.openBox('diary');
  await initializeDefaultLists();
  runApp(MyApp());
}

// Initialize
Future<bool> isFirstLaunch() async {
  return !((Hive.box('settings').get('isInitialized', defaultValue: false) as bool)
        && (Hive.box('diary').get('isInitialized', defaultValue: false) as bool));
}

Future<void> setInitialized() async {
  await Hive.box('settings').put('isInitialized', true);
  await Hive.box('diary').put('isInitialized', true);
}

Future<void> initializeDefaultLists() async {
  final boxLocalLists = Hive.box<List>('localLists');
  // Initial lists
  if (boxLocalLists.isEmpty) {
    await boxLocalLists.put('早餐',
    ['Meal 1',
     'Meal 2',
     'Meal 3',
     'Meal 4',
     'Meal 5',]);
     await boxLocalLists.put('午晚餐',
    ['Meal 1',
     'Meal 2',
     'Meal 3',
     'Meal 4',
     'Meal 5',]);
  }

  for(int i=boxLocalLists.length-1;i>=0;i--){ localListOrder.add(boxLocalLists.keyAt(i)); }

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

// Functions for list edit
void newList(String name) {
  final box = Hive.box<List>('localLists');
  if (!box.containsKey(name)) { box.put(name, []); }
  localListOrder.clear();
  for(int i=0;i<box.length;i++){ localListOrder.add(box.keyAt(i)); }
}

bool editListName(String oldName, String newName) {
  final box = Hive.box<List>('localLists');
  if (box.containsKey(newName)) { // the key already exist
    return false;
  } else if (box.containsKey(oldName)) {
    final list = box.get(oldName, defaultValue: [])!.cast<String>();
    box.delete(oldName);
    box.put(newName, list);
  }
  for(int i=0;i<box.length;i++){
    if(localListOrder[i]==oldName){
      localListOrder[i] = newName;
    }
  }
  return true;
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

bool editItemName(String listName, String oldName, String newName) {
  final box = Hive.box<List>('localLists');
  final list = box.get(listName, defaultValue: [])!.cast<String>();
  if (list.contains(newName)) { // the key already exist
    return false;
  } else if (list.contains(oldName)) {
    list[list.indexOf(oldName)] = newName;
    box.delete(listName);
    box.put(listName, list);
  } return true;
}

void removeItem(String listName, String itemName) {
  final box = Hive.box<List>('localLists');
  final list = box.get(listName, defaultValue: [])!.cast<String>();
  list.remove(itemName);
  box.put(listName, list);
}

// Functions for diary entries
void newDiary(DateTime dt, String listName, String itemName) {
  final box = Hive.box<List>('diary');
  box.put(dt.toString() + listName + itemName, []);
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
          BottomNavigationBarItem(icon: const Icon(Icons.speed), label: 'Roulette'),
          BottomNavigationBarItem(icon: const Icon(Icons.article), label: 'Diary'),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedList,
      builder: (context, selected, child) {
        return ValueListenableBuilder<Box<List>>(
          valueListenable: Hive.box<List>('localLists').listenable(),
          builder: (context, box, child) {
            final rouletteList = box.get(selected, defaultValue: [])!.cast<String>();

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
                                MaterialPageRoute(
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
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(selected),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: MyRoulette(
                                  group: group,
                                  controller: _controller,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  size: 50,
                                  color: const Color.fromARGB(255, 255, 139, 101),
                                ),
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
          },
        );
      },
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
      appBar: AppBar(
        title: Text('編輯清單'),
        actions: [
          IconButton( // Add new list
            onPressed: () async {
              final newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOrEditName(),
                  ),
              );
              if (newName != null) {
                setState(() { newList(newName); });
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
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

class AddOrEditName extends StatefulWidget {
  final String prevName;
  AddOrEditName({super.key, this.prevName = ''});

  @override
  _AddOrEditNameState createState() => _AddOrEditNameState();
}

class _AddOrEditNameState extends State<AddOrEditName> {
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
    return Scaffold(
      appBar: AppBar(title: Text((widget.prevName=='') ? '新增項目' : '編輯名稱')),
      body: Form(
        key: _newName,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                // The validator receives the text that the user has entered.
                validator: (value) { return null; },
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: (widget.prevName=='') ? '' : widget.prevName,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  Navigator.pop(context,nameController.text);
                },
                child: const Text('確定'),
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class EditItemPage extends StatefulWidget {
  String listName;
  EditItemPage({super.key, required this.listName});

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
          IconButton( // Add new item
            onPressed: () async {
              final newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOrEditName(),
                  ),
              );
              if (newName != null) {
                setState(() { newItem(widget.listName,newName); });
              }
            },
            icon: const Icon(Icons.add),
          ),
          IconButton( // Edit
            onPressed: () async {
              final newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOrEditName(prevName:widget.listName),
                  ),
              );
              if (newName != null) {
                final success = editListName(widget.listName, newName);
                if(success){ setState(() { widget.listName = newName; }); }
                else{
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('已經有同名的清單了!'),
                      );
                    },
                  );
                }
              }
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<List> box, child) {
          final itemList = box.get(widget.listName, defaultValue: [])!.cast<String>();
          return ReorderableListView.builder( // List
            padding: const EdgeInsets.all(12.0),
            itemCount: itemList.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final key = itemList.removeAt(oldIndex);
              itemList.insert(newIndex, key);
              box.put(widget.listName, itemList); // Save the reordered list back to Hive
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
  String curItem;
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
          IconButton( // Edit
            onPressed: () async {
              final newName = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOrEditName(prevName:widget.curItem),
                ),
              );
              if (newName != null) {
                final success = editItemName(widget.curList, widget.curItem, newName);
                if(success){ setState(() { widget.curItem = newName; }); }
                else{
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('已經有同名的項目了!'),
                      );
                    },
                  );
                }
              }
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton( // Delete
            onPressed: () { removeItem(widget.curList, widget.curItem); setState(() {}); }, icon: const Icon(Icons.delete),
          ),
        ]
      ),
    );
  }
}

class DiaryPage extends StatefulWidget {
  DiaryPage({super.key});

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('用餐日記'),
        actions: [
          IconButton( // Add new item
            onPressed: () async {
              final newValue = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOrEditDiary(),
                  ),
              );
              if (newValue != null) {
                setState(() { newDiary(newValue, newValue, newValue); }); // In progress...
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        // In progress...
      ),
    );
  }
}

class AddOrEditDiary extends StatefulWidget {
  final String prevValue;
  AddOrEditDiary({super.key, this.prevValue = ''});

  @override
  _AddOrEditDiaryState createState() => _AddOrEditDiaryState();
}

class _AddOrEditDiaryState extends State<AddOrEditDiary> {
  final _newValue = GlobalKey<FormState>();
  final nameController = TextEditingController();
  ValueNotifier<DateTime> dateTime = ValueNotifier<DateTime>(DateTime.now());

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text((widget.prevValue=='') ? '新增日記' : '編輯日記')),
      body: Form(
        key: _newValue,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  ValueListenableBuilder<DateTime>(
                    valueListenable: dateTime,
                    builder: (BuildContext context, DateTime value, Widget? child) {
                      return Text(value.toString());
                    },
                  ),
                  IconButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: dateTime.value,
                        firstDate: DateTime(dateTime.value.year-1),
                        lastDate: DateTime(dateTime.value.year+1),
                      );
                      final TimeOfDay? pickedTime = await showTimePicker(
                        initialTime: TimeOfDay.now(),
                        context: context,
                      );
                      if(pickedDate!=null && pickedTime!=null){
                        setState( () {
                          dateTime.value = pickedDate.add(
                            Duration(hours: pickedTime.hour, minutes: pickedTime.minute)
                          );
                        } );
                      }
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              TextFormField(
                controller: nameController,
                // The validator receives the text that the user has entered.
                validator: (value) { return null; },
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: (widget.prevValue=='') ? '' : widget.prevValue,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  Navigator.pop(context,nameController.text);
                },
                child: const Text('確定'),
              ),
            ]
          ),
        ),
      ),
    );
  }
}