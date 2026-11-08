// Package
// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data

// Files
import '../basic/classes.dart';
import '../basic/functions.dart';
import 'global_widgets.dart';
import 'list_edit.dart';

// Item edit
class EditItemPage extends StatefulWidget {
  String listName;
  EditItemPage({super.key, required this.listName});

  @override
  EditItemPageState createState() => EditItemPageState();
}

class EditItemPageState extends State<EditItemPage> {
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
              if (context.mounted) {
                final success = editListName(widget.listName, newName);
                if(success){ setState(() { widget.listName = newName; }); }
                else{
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: const Text('已經有同名的清單了!'),
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
          final itemList = readItemMenu(widget.listName).items;
          return ReorderableListView.builder( // List
            padding: const EdgeInsets.all(12.0),
            itemCount: itemList.length,
            onReorderItem: (oldIndex, newIndex) {
              if (oldIndex < newIndex) newIndex -= 1;
              if (newIndex >= itemList.length) newIndex -= 1;
              final key = listBox.get(widget.listName).removeAt(oldIndex);
              listBox.get(widget.listName).insert(newIndex, key);
            },
            itemBuilder: (context, index) {
              return ItemEditBox(key: ValueKey(itemList[index].name), curList: widget.listName, curItem: itemList[index], index: index);
            },
          );
        },
      ),
    );
  }
}

class ItemEditBox extends StatelessWidget {
  final String curList;
  Item curItem;
  final int index;
  ItemEditBox({super.key, required this.curList, required this.curItem, required this.index});

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
            index: index,
            child: IconButton( // Move layers
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ),
          Expanded(
            child: Text( // List name
              curItem.name,
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
                  builder: (context) => AddOrEditName(prevName:curItem.name),
                ),
              );
              if (context.mounted) {
                final result = editItemName(curItem, curList, newName);
                switch(result){
                  case(1): { // succeed
                    Item newItem = Item( name:newName, weight:curItem.weight, tags:curItem.tags );
                    curItem = newItem;
                  } case(-1): { // failed, name cannot be empty
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: const Text('名稱不可為空！'),
                        );
                      },
                    );
                  } case(-2): { // failed, such name already exists
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: const Text('已經有同名的項目了！'),
                        );
                      },
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton( // Delete
            onPressed: () async {
              final result = await Navigator.of(context).push(DeleteConfirm());
              if(result!=null && result){ removeItem(curList, curItem); }
            }, icon: const Icon(Icons.delete),
          ),
        ]
      ),
    );
  }
}
