// Packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

// Classes
class MultiValueListenableBuilder extends AnimatedWidget {
  final List<ValueListenable> listenables;
  final WidgetBuilder builder;

  MultiValueListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
  }) : super(listenable: Listenable.merge(listenables));

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

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

class ItemMenu { // name is used as key in box
  int order;
  final List<Item> items;
  ItemMenu({ required this.order, required this.items });
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