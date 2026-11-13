// Packages
import 'package:hive_flutter/hive_flutter.dart'; // For local data
import 'package:intl/intl.dart';

// Files
import 'classes.dart';
import 'global_vars.dart';

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

// Initialize
Future<bool> isFirstLaunch() async {
  return !(Hive.box('settings').get('isInitialized', defaultValue: false) as bool);
}

Future<void> setInitialized() async {
  await Hive.box('settings').put('isInitialized', true);
}

Future<void> initializeDefaultLists() async {
  final boxLocalLists = Hive.box('localLists');
  // Initial lists
  if (boxLocalLists.isEmpty) {
    await boxLocalLists.put( '早餐', ItemMenu(order: 0, items: [ Item(name:'Meal 1'), Item(name:'Meal 2'), Item(name:'Meal 3'), Item(name:'Meal 4'), Item(name:'Meal 5') ]) );
    await boxLocalLists.put( '午晚餐', ItemMenu(order: 1, items: [ Item(name:'Meal 1'), Item(name:'Meal 2'), Item(name:'Meal 3'), Item(name:'Meal 4'), Item(name:'Meal 5') ]) );
  }

  for(int i=boxLocalLists.length-1;i>=0;i--){ localListOrder.add(boxLocalLists.keyAt(i)); }

  // Flagging
  if (await isFirstLaunch()) { await setInitialized(); }
}

// Functions for roulette edit
void updateWeights(){
  final listBox = Hive.box('localLists');
  final diaryBox = Hive.box<Diary>('diary');
  for(var listName in listBox.keys){ // Reset all weights before changes
    final list = listBox.get(listName).items;
    for(var item in list){
      editItemWeight(item,listName,1);
    }
  }
  for (var date in diaryBox.keys) { // If this food was recently ate, lower the weight
    var daysBefore = DateTime.now().difference(diaryBox.get(date)!.dateTime).inDays;
    var newWeight = 0.2*daysBefore-0.6;
    if(newWeight<0){ newWeight=0; }
    else if(newWeight>1){ newWeight=1; }

    var value = diaryBox.get(date);
    final menu = readItemMenu(value!.listName);
    final nameList = menu.items.map((item) => item.name).toList();
    final index = nameList.indexOf(value.itemName);
    if(index!=-1){
      editItemWeight(menu.items[index],value.listName,newWeight);
    }
  }
}

// Functions for list edit
void newList(String name) {
  final listsBox = Hive.box('localLists');
  if (!listsBox.containsKey(name)) { listsBox.put(name, <Item>[]); }
  localListOrder.clear();
  for(int i=0;i<listsBox.length;i++){ localListOrder.add(listsBox.keyAt(i)); }
}

bool editListName(String oldName, String newName) {
  final listBox = Hive.box('localLists');
  if (listBox.containsKey(newName)) { // the key already exist
    return false;
  } else if (listBox.containsKey(oldName)) {
    final list = readItemMenu(oldName);
    listBox.delete(oldName);
    listBox.put(newName, list);
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
  if (listBox.containsKey(name)) { listBox.delete(name); }
  localListOrder.clear();
  for(int i=0;i<listBox.length;i++){ localListOrder.add(listBox.keyAt(i)); }
}

void newItem(String listName, String itemName) {
  final listBox = Hive.box('localLists');
  final menu = readItemMenu(listName);
  // ! = Force to treat data as non-null
  // cast<T>() = Force assign every data value as T types.
  menu.items.add( Item(name: itemName) );
  listBox.put(listName, menu);
}

int editItemName(Item item, String listName, String newName) {
  final listBox = Hive.box('localLists');
  final menu = readItemMenu(listName);
  final nameList = menu.items.map((item) => item.name).toList();
  if (newName.isEmpty){ // the name already exist
    return -1;
  } else if (nameList.contains(newName)) { // the name already exist
    return -2;
  } else if (nameList.contains(item.name)) {
    final index = nameList.indexOf(item.name);
    menu.items.removeAt(index);
    menu.items.insert(index, Item(name:newName, weight:item.weight, tags:item.tags));
    listBox.delete(listName);
    listBox.put(listName, menu);
  } return 1;
}

bool editItemWeight(Item item, String listName, double newWeight) {
  final listBox = Hive.box('localLists');
  final menu = readItemMenu(listName);
  final nameList = menu.items.map((item) => item.name).toList();
  if (nameList.contains(item.name)) {
    final index = nameList.indexOf(item.name);
    menu.items.remove(item);
    menu.items.insert(index,Item(name:item.name, weight:newWeight, tags:item.tags));
    listBox.delete(listName);
    listBox.put(listName, menu);
  } return true;
}

bool removeItem(String listName, Item item) {
  final listBox = Hive.box('localLists');
  final menu = readItemMenu(listName);
  final nameList = menu.items.map((item) => item.name).toList();
  if (nameList.contains(item.name)){
    final index = nameList.indexOf(item.name);
    menu.items.removeAt(index);
    listBox.put(listName, menu);
    return true;
  } return false;
}

// Functions for diary entries
bool onSameDay(DateTime a, DateTime b) {
  if(a.year==b.year && a.month==b.month && a.day==b.day){
    return true;
  } else {
    return false;
  }
}

ItemMenu readItemMenu(String listName) {
  final box = Hive.box('localLists');
  final raw = box.get(listName);
  if (raw.items is List) {
    final List<Item> menuItems = [];
    for (var element in raw.items) {
      if (element is Item) { menuItems.add(element); }
      else if (element is String) { menuItems.add(Item(name: element)); }
      else { menuItems.add(Item(name: element?.toString() ?? '')); }
    } return ItemMenu(order:raw.order, items:menuItems);
  }
  
  return ItemMenu(order:-1, items:[]);
}

void newDiary(DateTime dt, String listName, String itemName, double itemWeight) {
  final box = Hive.box<Diary>('diary');
  String dtKey = DateFormat(dateFormatSec).format(dt);

  box.put( dtKey, Diary( dateTime:dt, listName:listName, itemName:itemName ) );
}

void editDiary(DateTime oldDt, String oldListName, String oldItemName, DateTime newDt, String newListName, String newItemName) {
  final box = Hive.box<Diary>('diary');
  String newDtKey = DateFormat(dateFormatSec).format(newDt);
  String oldDtKey = DateFormat(dateFormatSec).format(oldDt);
  box.delete(oldDtKey);
  box.put( newDtKey, Diary( dateTime:newDt, listName:newListName, itemName:newItemName ) );
}

void removeDiary(DateTime dt) {
  final box = Hive.box<Diary>('diary');
  String dtKey = DateFormat(dateFormatSec).format(dt);
  if(box.containsKey(dtKey)) { box.delete(dtKey); }
}

// Misc
void migration(Box box, String listName) {
  var newItemList = ItemMenu(order:-1, items:[]);
  final rawData = box.get(listName, defaultValue: []);
  for (var element in rawData) {
    if (element is String) {
      newItemList.items.add(Item(name: element));
    } else if (element is Item) {
      newItemList.items.add(element);
    }
  }
  box.put(listName, newItemList);
}