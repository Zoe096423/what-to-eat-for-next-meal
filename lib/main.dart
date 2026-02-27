// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, must_be_immutable
// Roulette source: https://pub.dev/packages/roulette

// In progress: Make the diary page functionable.
// In progress: Make item weights change, and make the roulette reflect weight changes.
// In progress: Add the function of manually changing the percentage in editItem.
// In progress: Change the app icon and name.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:roulette/roulette.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data
import 'package:intl/intl.dart'; // For dateTime format
import 'package:const_date_time/const_date_time.dart'; //For const dateTime

enum RGB {R,G,B}
String dateFormat = 'yyyy-MM-dd HH:mm';
String dateFormatSec = 'yyyy-MM-dd HH:mm:ss';
const defaultDt = ConstDateTime.utc(2022, 10, 27);

class Tag {
  final String name;
  bool enable = true;
  Tag({ required this.name, this.enable = true });
}

class TagAdapter extends TypeAdapter<Tag> {
  @override
  final int typeId = 0;

  @override
  Tag read(BinaryReader reader) {
    final name = reader.readString();
    final enable = reader.readBool();
    return Tag(
      name: name,
      enable: enable,
    );
  }

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer.writeString(obj.name);
    writer.writeBool(obj.enable);
  }
}

class Item {
  final String name;
  final double weight;
  final List<Tag> tags;
  Item({ required this.name, this.weight = 1, this.tags = const [] });
}

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 1;

  @override
  Item read(BinaryReader reader) {
    final name = reader.readString();
    final weight = reader.readDouble();
    // null guard start
    final rawTags = reader.read();
    List<Tag> tags;
    if (rawTags is List<Tag>) { tags = rawTags; }
    else if (rawTags == null) { tags = const []; }
    else { tags = (rawTags as List).map((e) => e is Tag ? e : Tag(name: e?.toString() ?? '')).toList(); }
    // null guard end
    return Item(
      name: name,
      weight: weight,
      tags: tags,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.weight);
    writer.write(obj.tags);
  }
}

class Diary {
  final DateTime dateTime;
  final String listName;
  final String itemName;

  const Diary({
    required this.dateTime,
    required this.listName,
    required this.itemName,
  });
}

class DiaryEntry extends Diary {
  final double itemWeight;

  DiaryEntry({
    required super.dateTime,
    required super.listName,
    required super.itemName,
    required this.itemWeight,
  });
}

class DiaryAdapter extends TypeAdapter<Diary> {
  @override
  final int typeId = 2;

  @override
  Diary read(BinaryReader reader) {
    final dtMillis = reader.readInt();
    final listName = reader.readString();
    final itemName = reader.readString();
    return Diary(
      dateTime: DateTime.fromMillisecondsSinceEpoch(dtMillis),
      listName: listName,
      itemName: itemName,
    );
  }

  @override
  void write(BinaryWriter writer, Diary obj) {
    writer.writeInt(obj.dateTime.millisecondsSinceEpoch);
    writer.writeString(obj.listName);
    writer.writeString(obj.itemName);
  }
}

ValueNotifier<String> selectedList = ValueNotifier('午晚餐');
final List<String> localListOrder = [];

void migration(Box box, String listName) {
  final rawData = box.get(listName, defaultValue: []);
  List<Item> items = [];
  for (var element in rawData) {
    if (element is String) {
      items.add(Item(name: element));
    } else if (element is Item) {
      items.add(element);
    }
  }
  box.put(listName, items);
}

// Helper that always returns a fresh List<Item> regardless of what Hive stored.
List<Item> readItemList(String key) {
  final box = Hive.box('localLists');
  final raw = box.get(key);
  if (raw is List) {
    final List<Item> output = [];
    for (var element in raw) {
      if (element is Item) { output.add(element); }
      else if (element is String) { output.add(Item(name: element)); }
      else { output.add(Item(name: element?.toString() ?? '')); }
    }
    return output;
  }
  return <Item>[];
}

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
  //Hive.box<List<Item>>('localLists').clear(); //debug

  await Hive.openBox('itemWeights');
  await Hive.openBox<Diary>('diary');
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
  final boxLocalLists = Hive.box('localLists');
  final boxItemWeight = Hive.box('itemWeights');
  // Initial lists
  if (boxLocalLists.isEmpty) {
    await boxLocalLists.put('早餐',[ Item(name:'Meal 1'), Item(name:'Meal 2'), Item(name:'Meal 3'), Item(name:'Meal 4'), Item(name:'Meal 5') ]);
    await boxLocalLists.put('午晚餐',[ Item(name:'Meal 1'), Item(name:'Meal 2'), Item(name:'Meal 3'), Item(name:'Meal 4'), Item(name:'Meal 5') ]);
    await boxItemWeight.put('早餐', {'Meal 1':0.2, 'Meal 2':0.2, 'Meal 3':0.2, 'Meal 4':0.2, 'Meal 5':0.2});
    await boxItemWeight.put('午晚餐', {'Meal 1':0.2, 'Meal 2':0.2, 'Meal 3':0.2, 'Meal 4':0.2, 'Meal 5':0.2});
  }

  for(int i=boxLocalLists.length-1;i>=0;i--){ localListOrder.add(boxLocalLists.keyAt(i)); }

  // Flagging
  if (await isFirstLaunch()) { await setInitialized(); }
}

// Local save/load (outdated)
/*Future<void> saveAllLists(list<String, List<String>> lists) async {
  final listBox = Hive.box<List<Item>>('localLists');
  print('Saving lists...');
  //await box.clear(); // Optional: Fully replace existing data
  for (var entry in lists.entries) {
    await box.put(entry.key, entry.value);
  }
  print('All lists saved successfully!');
}

list<String, List<String>> loadAllLists() {
  final listBox = Hive.box<List<Item>>('localLists');
  print('Loading lists...');
  return {
    for (var key in box.keys)
      key.toString(): box.get(key, defaultValue: [])!.cast<String>(),
  };
}*/

// Functions for list edit
void newList(String name) {
  final listsBox = Hive.box('localLists');
  final itemWeightBox = Hive.box('itemWeights');
  if (!listsBox.containsKey(name)) { listsBox.put(name, <Item>[]); }
  if (!itemWeightBox.containsKey(name)) { itemWeightBox.put(name, <String,double>{}); }
  localListOrder.clear();
  for(int i=0;i<listsBox.length;i++){ localListOrder.add(listsBox.keyAt(i)); }
}

bool editListName(String oldName, String newName) {
  final listBox = Hive.box('localLists');
  final itemWeightBox = Hive.box('itemWeights');
  if (listBox.containsKey(newName)) { // the key already exist
    return false;
  } else if (listBox.containsKey(oldName)) {
    final list = readItemList(oldName);
    final itemWeightsRaw = itemWeightBox.get(oldName, defaultValue: <String,double>{})!;
    final itemWeights = Map<String,double>.from(itemWeightsRaw as Map);
    listBox.delete(oldName);
    listBox.put(newName, list);
    itemWeightBox.delete(oldName);
    itemWeightBox.put(newName,itemWeights);
  }
  for(int i=0;i<listBox.length;i++){
    if(localListOrder[i]==oldName){
      localListOrder[i] = newName;
    }
  }
  return true;
}

void removeList(String name) {
  final listBox = Hive.box('localLists');
  final itemWeightBox = Hive.box('itemWeights');
  if (listBox.containsKey(name)) { listBox.delete(name); }
  if (itemWeightBox.containsKey(name)) { itemWeightBox.delete(name); }
  localListOrder.clear();
  for(int i=0;i<listBox.length;i++){ localListOrder.add(listBox.keyAt(i)); }
}

void newItem(String listName,String itemName) {
  final listBox = Hive.box('localLists');
  final itemWeightBox = Hive.box('itemWeights');
  final list = readItemList(listName);
  // ! = Force to treat data as non-null
  // cast<T>() = Force assign every data value as T types.
  list.add( Item(name:itemName) );
  listBox.put(listName, list);
  itemWeightBox.put(listName,{itemName:1}); // In progress...
}

bool editItemName(Item item, String listName, String newName) {
  final listBox = Hive.box('localLists');
  final itemWeightBox = Hive.box('itemWeights');
  final list = readItemList(listName);
  final nameList = list.map((item) => item.name).toList();
  if (nameList.contains(newName)) { // the name already exist
    return false;
  } else if (nameList.contains(item.name)) {
    final index = nameList.indexOf(item.name);
    final itemWeightsRaw = itemWeightBox.get(listName, defaultValue: <String,double>{})!;
    final itemWeightsMap = Map<String,double>.from(itemWeightsRaw as Map);
    final double? itemWeight = itemWeightsMap[item.name];
    list.remove(item);
    list.insert(index,Item(name:newName, weight:item.weight, tags:item.tags));
    itemWeightsMap.remove(item.name);
    itemWeightsMap.addAll({newName:itemWeight!});
    listBox.delete(listName);
    listBox.put(listName, list);
    itemWeightBox.delete(listName);
    itemWeightBox.put(listName,itemWeightsMap);
  } return true;
}

void removeItem(String listName, Item item) {
  final listBox = Hive.box('localLists');
  final itemWeightBox = Hive.box('itemWeights');
  final list = readItemList(listName);
  final rawMap = itemWeightBox.get(listName, defaultValue: <String,double>{})!;
  final itemWeightsMap = Map<String, double>.from(rawMap as Map);
  list.remove(item);
  itemWeightsMap.remove(item.name);
  listBox.put(listName, list);
  itemWeightBox.put(listName, itemWeightsMap);
}

// Functions for diary entries
void newDiary(DateTime dt, String listName, String itemName, double itemWeight) {
  final box = Hive.box<Diary>('diary');
  final weight = Hive.box('itemWeights');
  String dtKey = DateFormat(dateFormatSec).format(dt);

  box.put( dtKey, Diary( dateTime:dt, listName:listName, itemName:itemName ) );
  weight.add({ itemName:itemWeight });
}

bool editDiary(DateTime oldDt, String oldListName, String oldItemName,
               DateTime newDt, String newListName, String newItemName) {

  final box = Hive.box<Diary>('diary');
  String newDtKey = DateFormat(dateFormatSec).format(newDt);
  String oldDtKey = DateFormat(dateFormatSec).format(oldDt);

  if (box.containsKey(newDtKey)) { // the exact DateTime already exist
    return false;
  } else if (box.containsKey(oldDtKey)) {
    box.delete(oldDtKey);
    box.put( newDtKey, Diary( dateTime:newDt, listName:newListName, itemName:oldItemName ) );
  }
  return true;
}

void removeDiary(DateTime dt) {
  final box = Hive.box<Diary>('diary');
  String dtKey = DateFormat(dateFormatSec).format(dt);
  if(box.containsKey(dtKey)) { box.delete(dtKey); }
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
        return ValueListenableBuilder<Box>(
          valueListenable: Hive.box('localLists').listenable(),
          builder: (context, box, child) {
            final roulettelist = readItemList(selected).map((item) => item.name).toList();

            // Color control
            final List<Color> colors = <Color>[];
            final int value = roulettelist.length*100;
            final List<int> sat = [150,1,255];
            final List<int> cRange = [255,0,100];
            
            for(int i=0;i<roulettelist.length;i++){
              int color(int x) => ((sin(cRange[x]/roulettelist.length*i)*value).round()+255-cRange[x])%sat[x];
              colors.add(Color.fromARGB(255, color(0), color(1), color(2)).withAlpha(70),);
            }

            // Generating roulette
            late final group = RouletteGroup.uniform(
              roulettelist.length,
              colorBuilder: (index) => colors[index%colors.length],
              textBuilder: (index) => roulettelist[index],
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
                              final int resultInt = _random.nextInt(roulettelist.length);
                              final completed = await _controller.rollTo(
                                resultInt,
                                clockwise: _clockwise,
                                offset: _random.nextDouble(),
                              );
                  
                              if (completed) {
                                String result = roulettelist[resultInt];
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
  final listBox = Hive.box('localLists');

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
      body: ValueListenableBuilder<Box<dynamic>>(
        valueListenable: listBox.listenable(),
        builder: (context, Box box, child) {
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
                index: Hive.box('localLists').keys.toList().indexOf(curList),
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
  final listBox = Hive.box('localLists');

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
      body: ValueListenableBuilder<Box<dynamic>>(
        valueListenable: listBox.listenable(),
        builder: (context, Box box, child) {
          final itemList = readItemList(widget.listName);
          return ReorderableListView.builder( // List
            padding: const EdgeInsets.all(12.0),
            itemCount: itemList.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final key = itemList.removeAt(oldIndex);
              itemList.insert(newIndex, key);
            },
            itemBuilder: (context, index) {
              return ItemEditBox(key: ValueKey(itemList[index]), curList: widget.listName, curItem: itemList[index], index: index);
            },
          );
        },
      ),
    );
  }
}

class ItemEditBox extends StatefulWidget {
  final String curList;
  Item curItem;
  final int index;
  ItemEditBox({super.key, required this.curList, required this.curItem, required this.index});

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
            index: widget.index,
            child: IconButton( // Move layers
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ),
          Expanded(
            child: Text( // List name
              widget.curItem.name,
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
                  builder: (context) => AddOrEditName(prevName:widget.curItem.name),
                ),
              );
              if (newName != null) {
                final success = editItemName(widget.curItem, widget.curList, newName);
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
  final diaryBox = Hive.box<Diary>('diary');

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
                setState(() { newDiary(newValue.dateTime, newValue.listName, newValue.itemName, newValue.itemWeight); });
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: diaryBox.listenable(),
        builder: (context, Box<Diary> box, child) {
          var diaryList = box.values.toList();
          return ListView.builder( // List
            padding: const EdgeInsets.all(12.0),
            itemCount: diaryList.length,
            itemBuilder: (context, index) {
              return DiaryBox(key: ValueKey(diaryList[index]), curDiary: diaryList[index], index: index);
            },
          );
        },
      ),
    );
  }
}

class DiaryBox extends StatefulWidget {
  Diary curDiary;
  final int index;
  DiaryBox({super.key, required this.curDiary, required this.index});

  @override
  _DiaryBoxState createState() => _DiaryBoxState();
}

class _DiaryBoxState extends State<DiaryBox>{

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            const SizedBox( width: 20 ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text( // dateTime
                    DateFormat(dateFormat).format(widget.curDiary.dateTime),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black
                    ),
                  ),
                  Text( // itemName
                    widget.curDiary.itemName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  ),
                  if(widget.curDiary.listName!="")
                    Text( // listName
                      widget.curDiary.listName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black
                      ),
                    ),
                ],
              ),
            ),
            IconButton( // Edit
              onPressed: () async {
                final Diary newData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddOrEditDiary(prevValue: widget.curDiary), // In progress...
                  ),
                );
                if (newData != widget.curDiary) {
                  final success = editDiary(widget.curDiary.dateTime, widget.curDiary.listName, widget.curDiary.itemName,
                                            newData.dateTime, newData.listName, newData.itemName);
                  if(success){ setState(() { widget.curDiary = Diary( dateTime:widget.curDiary.dateTime, listName:widget.curDiary.listName, itemName:newData.itemName ); }); }
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
              onPressed: () { removeDiary(widget.curDiary.dateTime); setState(() {}); }, icon: const Icon(Icons.delete),
            ),
          ]
        ),
      ),
    );
  }
}

class AddOrEditDiary extends StatefulWidget {
  final Diary prevValue;
  AddOrEditDiary({super.key, this.prevValue = const Diary( dateTime: defaultDt, listName:'', itemName:'')});
  bool edit = false;

  @override
  _AddOrEditDiaryState createState() => _AddOrEditDiaryState();
}

class _AddOrEditDiaryState extends State<AddOrEditDiary> {
  ValueNotifier<DateTime> dateTime = ValueNotifier<DateTime>(DateTime.now());
  late String listName;
  late String itemName;
  late String addToList;
  final listsBox = Hive.box('localLists');

  bool newFood = false;
  bool addToRoulette = false;
  bool changeWeight = false;
  double itemWeight = 1; // In progress...

  final _newValue = GlobalKey<FormState>();
  final itemController = TextEditingController();
  
  @override
  void initState() {
    super.initState();

    // If new entry
    listName = localListOrder.isNotEmpty ? localListOrder[0] : '';
    addToList = localListOrder.isNotEmpty ? localListOrder[0] : '';
    final items = _getItemNamesForList(listName);
    itemName = items.isNotEmpty ? items[0] : '';

    // If editing
    if (widget.prevValue.dateTime != defaultDt) {
      widget.edit = true;
      if(widget.prevValue.listName=='新食物') {
        newFood = true;
        itemController.text = widget.prevValue.itemName;
      } else {
        listName = widget.prevValue.listName;
        itemName = widget.prevValue.itemName;
      }
    }
  }
  
  List<String> _getItemNamesForList(String list) {
    return readItemList(list).map((item) => item.name).toList();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    itemController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text( widget.edit ? '編輯日記' : '新增日記')),
      body: Form(
        key: _newValue,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row( // Date & time
                children: [
                  Text('日期&時間:'),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<DateTime>(
                    valueListenable: dateTime,
                    builder: (BuildContext context, DateTime value, Widget? child) {
                      return Text(DateFormat(dateFormat).format(value));
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
              Row( // Choose method of recording
                children: [
                  Text('要記錄什麼? '),
                  IconButton( // Selection
                    onPressed: () { setState((){ newFood = false; }); },
                    icon: (newFood==false) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                  ),
                  Text('轉盤內的食物'),
                  IconButton( // Selection
                    onPressed: () { setState((){ newFood = true; }); },
                    icon: (newFood==true) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                  ),
                  Text('新食物'),
                ],
              ),
              if(!newFood)
                Row( // Record food
                  children: [
                    Text("吃了"),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 125,
                      child: DropdownButton<String>( // List
                        value: listName.isNotEmpty ? listName : null,
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() { 
                            listName = newValue!;
                            // Update itemName to first item of new list
                            final items = _getItemNamesForList(listName);
                            itemName = items[0];
                          });
                        },
                        items: localListOrder.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 125,
                      child: DropdownButton<String>( // Food name
                        value: itemName.isNotEmpty ? itemName : null,
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() { itemName = newValue!; });
                        },
                        items: _getItemNamesForList(listName).map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row( // Record new food
                      children: [
                        Text("吃了"),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 70,
                          width: 275,
                          child: TextFormField(
                            controller: itemController,
                            // The validator receives the text that the user has entered.
                            validator: (value) { return null; },
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              labelText: widget.edit ? widget.prevValue.itemName : '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row( // Add new food to roulette or not
                      children: [
                        Text('是否將新的食物登錄到轉盤?'),
                        IconButton( // Selection
                          onPressed: () { setState((){ addToRoulette = true; }); },
                          icon: (addToRoulette==true) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                        ),
                        Text('是'),
                        IconButton( // Selection
                          onPressed: () { setState((){ addToRoulette = false; }); },
                          icon: (addToRoulette==false) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                        ),
                        Text('否'),
                      ],
                    ),
                    if(addToRoulette)
                      Column(
                        children: [
                          Row( // Which list of the roulette to add to
                            children: [
                              Text('加進'),
                              DropdownButton<String>( // List
                                value: addToList.isNotEmpty ? addToList : null,
                                icon: const Icon(Icons.arrow_drop_down),
                                onChanged: (String? newValue) {
                                  setState(() { 
                                    addToList = newValue!;
                                    // Update itemName to first item of new list
                                    final items = _getItemNamesForList(addToList);
                                    itemName = items[0];
                                  });
                                },
                                items: localListOrder.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              Text('，權重: '),
                              IconButton( // Selection
                                onPressed: () { setState((){ changeWeight = false; }); },
                                icon: (changeWeight==false) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                              ),
                              Text('預設'),
                              IconButton( // Selection
                                onPressed: () { setState((){ changeWeight = true; }); },
                                icon: (changeWeight==true) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                              ),
                              Text('自訂'),
                            ],
                          ),
                          if(changeWeight)
                            Row( // Weight slider
                              children:[
                                SizedBox(
                                  width: 300,
                                  child: Slider(
                                    value: itemWeight,
                                    min: 0,
                                    max: 100,
                                    divisions: 20,
                                    label: '${itemWeight.round()}%',
                                    onChanged: (double value) {
                                      setState(() { itemWeight = value; });
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ]
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if(newFood && !addToRoulette){ listName = "新食物"; }
                  // Validate returns true if the form is valid, or false otherwise.
                  Navigator.pop(context, DiaryEntry(
                    dateTime: dateTime.value,
                    listName: listName,
                    itemName: itemController.text=='' ? itemName : itemController.text,
                    itemWeight: itemWeight));
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