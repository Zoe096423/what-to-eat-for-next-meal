// Packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data

// Files
import '../basic/functions.dart';
import '../basic/global_vars.dart';
import 'global_widgets.dart';
import "item_edit.dart";

// List edit
class EditListPage extends StatefulWidget {
  @override
  EditListPageState createState() => EditListPageState();
}

class EditListPageState extends State<EditListPage> {
  final listBox = Hive.box('localLists');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯清單'),
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
            onReorderItem: (oldIndex, newIndex) {
              if (oldIndex < newIndex) newIndex -= 1;
              if (newIndex >= box.length) newIndex -= 1;
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
                onPressed: () async {
                  final result = await Navigator.of(context).push(DeleteConfirm());
                  if(result!=null && result){ removeList(curList); }
                }, icon: const Icon(Icons.delete),
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
  AddOrEditNameState createState() => AddOrEditNameState();
}

class AddOrEditNameState extends State<AddOrEditName> {
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
                validator: (value) {
                  value = (widget.prevName=='') ? '' : widget.prevName;
                  return null; },
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
