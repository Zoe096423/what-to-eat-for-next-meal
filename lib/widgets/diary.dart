// Packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data
import 'package:intl/intl.dart'; // For dateTime format
import 'package:chinese_number/chinese_number.dart';

// Files
import '../basic/classes.dart';
import '../basic/functions.dart';
import '../basic/global_vars.dart';
import 'global_widgets.dart';

// Diary
class ScrollWeekDay extends StatefulWidget {
  ScrollWeekDay({super.key});

  @override
  ScrollWeekDayState createState() => ScrollWeekDayState();
}

class ScrollWeekDayState extends State<ScrollWeekDay> {
  late final List<DateTime> _dates;
  final _weekdays = ["一", "二", "三", "四", "五", "六", "日"];

  @override
  void initState() {
    super.initState();
    _dates = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day + index),
    );
  }

  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        SizedBox(
          height: 28,
          width: MediaQuery.widthOf(context)/1.37,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left:8, right:8, top:8),
            itemCount: 7,
            separatorBuilder: (_, _) => SizedBox(width: (MediaQuery.widthOf(context)-96)/9.8),
            itemBuilder:(context, index) {
              final date = _dates[index];
              return Text( // Day of week
                _weekdays[date.weekday - 1],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: (){},
              icon: const Icon(Icons.chevron_left),
            ),
            SizedBox(
              height: 48,
              width: MediaQuery.widthOf(context)-96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 2),
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = DateUtils.isSameDay(date, selectedDate);
                  return Material(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        width: (MediaQuery.widthOf(context)-96)/7-8.6,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text( // Day
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              onPressed: (){},
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

class DiaryPage extends StatefulWidget {
  DiaryPage({super.key});

  @override
  DiaryPageState createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage>{
  final diaryBox = Hive.box<Diary>('diary');
  late List<Diary> diaryListAll, diaryListToday, diaryList;

  @override
  void initState(){
    super.initState();
    diaryListAll = [ for(var entry in diaryBox.values.toList()) entry ];
    diaryListToday = [ for(var entry in diaryBox.values.toList()) if(onSameDay(entry.dateTime,selectedDate)) entry ];
    diaryList = diaryListToday;
  }

  List<Diary> refreshDiaryListToday(){
    return [ for(var entry in diaryBox.values.toList()) if(onSameDay(entry.dateTime,selectedDate)) entry ];
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('用餐日記'),
        actions: [
          SizedBox(
            width: 162,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.all(1),
              title: const Text(
                '查看全部',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              value: diaryList==diaryListAll,
              onChanged:(bool? value) {
                setState(() {
                  diaryList = value! ? diaryListAll : diaryListToday;
                });
              },
            ),
          ),
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
      body: Column(
        children: [
          Align(
            alignment: AlignmentGeometry.xy(-0.85, 0),
            child: Text(
              "${localSelectedDate.month.toSimplifiedChineseNumber()}月", // Chinese & Mandarin
              //"${DateFormat("MMM").format(widget.localSelectedDate)}.", // English
              style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.4),
            ),
          ),
          ScrollWeekDay(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: diaryBox.listenable(),
              builder: (context, Box<Diary> box, child) {
                if(diaryList.isEmpty){
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(),
                      Text(
                        "日記空空的，這天吃了什麼呢",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  );
                } else{
                  if(diaryList==diaryListAll){ // latest date first
                    return ListView.builder( // List
                      padding: const EdgeInsets.all(12.0),
                      itemCount: diaryList.length,
                      itemBuilder: (context, index) {
                        // In progress: Align by date first (latest first), then time(oldest first)?
                        return DiaryBox(key: ValueKey(diaryList[diaryList.length-index-1]), curDiary: diaryList[diaryList.length-index-1], index: diaryList.length-index-1);
                      },
                    );
                  } else { // morning -> noon -> evening
                    return ValueListenableBuilder( // In progres: Does not work properly
                      valueListenable: ValueNotifier<DateTime>(selectedDate),
                      builder: (context, value, child){
                        return ListView.builder( // List
                          padding: const EdgeInsets.all(12.0),
                          itemCount: diaryList.length,
                          itemBuilder: (context, index) {
                            return DiaryBox(key: ValueKey(diaryList[index]), curDiary: diaryList[index], index: index);
                          },
                        );
                      },
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DiaryBox extends StatefulWidget {
  Diary curDiary;
  final int index;
  DiaryBox({super.key, required this.curDiary, required this.index});

  @override
  DiaryBoxState createState() => DiaryBoxState();
}

class DiaryBoxState extends State<DiaryBox>{

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
                final newData = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddOrEditDiary(prevValue: widget.curDiary), // In progress...
                  ),
                );
                if (newData!=null && newData!=widget.curDiary) {
                  newData.dateTime ??= widget.curDiary.dateTime;
                  newData.listName ??= widget.curDiary.listName;
                  newData.itemName ??= widget.curDiary.itemName;
                  editDiary(widget.curDiary.dateTime, widget.curDiary.listName, widget.curDiary.itemName, newData.dateTime, newData.listName, newData.itemName);
                  setState(() { widget.curDiary = Diary( dateTime:newData.dateTime, listName:newData.listName, itemName:newData.itemName ); });
                }
              },
              icon: const Icon(Icons.edit),
            ),
            IconButton( // Delete
              onPressed: () async {
                final result = await Navigator.of(context).push(DeleteConfirm());
                if(result!=null && result){ removeDiary(widget.curDiary.dateTime); setState(() {}); }
              }, icon: const Icon(Icons.delete),
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
  AddOrEditDiaryState createState() => AddOrEditDiaryState();
}

class AddOrEditDiaryState extends State<AddOrEditDiary> {
  ValueNotifier<DateTime> dateTime = ValueNotifier<DateTime>(DateTime.now());
  late String listName;
  late String itemName;
  late String addToList;
  final listsBox = Hive.box('localLists');
  late List<String> items;

  bool newFood = false;
  bool addToRoulette = false;
  bool changeWeight = false;
  double itemWeight = 1; // In progress...

  final _newValue = GlobalKey<FormState>();
  final itemController = TextEditingController();
  
  @override
  void initState() {
    super.initState();

    listName = localListOrder.isNotEmpty ? localListOrder[0] : '';
    addToList = localListOrder.isNotEmpty ? localListOrder[0] : '';
    items = _getItemNamesForList(listName);
    itemName = items.isNotEmpty ? items[0] : '';

    // If editing
    if (widget.prevValue.dateTime != defaultDt) {
      widget.edit = true;
      dateTime = ValueNotifier<DateTime>(widget.prevValue.dateTime);
      if(widget.prevValue.listName=='新食物') {
        newFood = true;
        itemController.text = widget.prevValue.itemName;
      } else {
        listName = widget.prevValue.listName;
        itemName = widget.prevValue.itemName;
        items = _getItemNamesForList(listName);
      }
    }
  }
  
  List<String> _getItemNamesForList(String list) {
    return readItemMenu(list).items.map((item) => item.name).toList();
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
                  const Text('日期&時間:'),
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
                        initialDate: widget.edit ? widget.prevValue.dateTime : dateTime.value,
                        firstDate: DateTime(dateTime.value.year-1),
                        lastDate: DateTime(dateTime.value.year+1),
                      );
                      if (context.mounted) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          initialTime: widget.edit ? TimeOfDay.fromDateTime(widget.prevValue.dateTime) : TimeOfDay.now(),
                          context: context,
                        );
                        if(pickedDate!=null && pickedTime!=null){
                          setState( () {
                            dateTime.value = pickedDate.add(
                              Duration(hours: pickedTime.hour, minutes: pickedTime.minute)
                            );
                          } );
                        }
                      }
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              Row( // Choose method of recording
                children: [
                  const Text('要記錄什麼? '),
                  IconButton( // Selection
                    onPressed: () { setState((){ newFood = false; }); },
                    icon: (newFood==false) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                  ),
                  const Text('轉盤內的食物'),
                  IconButton( // Selection
                    onPressed: () { setState((){ newFood = true; }); },
                    icon: (newFood==true) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                  ),
                  const Text('新食物'),
                ],
              ),
              if(!newFood)
                Row( // Record food
                  children: [
                    const Text("吃了"),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 125,
                      child: DropdownButton<String>( // List
                        value: (listName.isNotEmpty && localListOrder.any((element) => element == listName)) ? listName : null,
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() { 
                            listName = newValue!;
                            // Update itemName to first item of new list
                            items = _getItemNamesForList(listName);
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
                        value: (itemName.isNotEmpty && items.any((element) => element == itemName)) ? itemName : null,
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() { itemName = newValue!; });
                        },
                        items: items.map<DropdownMenuItem<String>>((String value) {
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
                        const Text("吃了"),
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
                        const Text('是否將新的食物登錄到轉盤?'),
                        IconButton( // Selection
                          onPressed: () { setState((){ addToRoulette = true; }); },
                          icon: (addToRoulette==true) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                        ),
                        const Text('是'),
                        IconButton( // Selection
                          onPressed: () { setState((){ addToRoulette = false; }); },
                          icon: (addToRoulette==false) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                        ),
                        const Text('否'),
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
                                  });
                                },
                                items: localListOrder.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              const Text('，權重: '),
                              IconButton( // Selection
                                onPressed: () { setState((){ changeWeight = false; }); },
                                icon: (changeWeight==false) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                              ),
                              const Text('預設'),
                              IconButton( // Selection
                                onPressed: () { setState((){ changeWeight = true; }); },
                                icon: (changeWeight==true) ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                              ),
                              const Text('自訂'),
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
                  if(addToList.isNotEmpty){ newItem(addToList, itemName); }
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