// Packages
import 'dart:math';
import 'package:roulette/roulette.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // For local data

// Files
import '../basic/classes.dart';
import '../basic/global_vars.dart';
import '../basic/functions.dart';
import 'list_edit.dart';

// Roulette
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
    return MultiValueListenableBuilder(
      listenables: [selectedList,Hive.box('localLists').listenable(),Hive.box<Diary>('diary').listenable()],
      builder: (context) {
        return ValueListenableBuilder<Box>(
          valueListenable: Hive.box('localLists').listenable(),
          builder: (context, box, child) {
            final roulettelistRaw = readItemMenu(selectedList.value).items.toList();

            // Update item weights depending on tags(in progress), diary entries
            final List<Item> roulettelist = [];
            updateWeights();
            for(var item in roulettelistRaw){
              if(item.weight!=0){ roulettelist.add(item); }
            }

            // Color control (HSV)
            final List<Color> colors = <Color>[];
            for(int i=0;i<roulettelist.length;i++){
              double h = 360.0/roulettelist.length*i;
              colors.add(HSVColor.fromAHSV(0.6, h, 0.2, 0.9).toColor());
            }

            // Old color control (RGB)
            /*final List<Color> colors = <Color>[];
            final int value = roulettelist.length*100;
            final List<int> sat = [150,1,255];
            final List<int> cRange = [255,0,100];
            
            for(int i=0;i<roulettelist.length;i++){
              int color(int x) => ((sin(cRange[x]/roulettelist.length*i)*value).round()+255-cRange[x])%sat[x];
              colors.add(Color.fromARGB(255, color(0), color(1), color(2)).withAlpha(70),);
            }*/

            // Generating roulette
            final units = <RouletteUnit>[];
            for (int i = 0; i < roulettelist.length; i += 1) {
              units.add(
                RouletteUnit(
                  text: roulettelist[i].name,
                  color: colors[i%colors.length],
                  textStyle:const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  weight: roulettelist[i].weight,
                ),
              );
            }
            late final group = RouletteGroup(units);

            return Scaffold(
              appBar: AppBar( title: const Text('等下吃什麼?'), ),
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
                                child: Text(selectedList.value),
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
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 50,
                                  color: Color.fromARGB(255, 255, 139, 101),
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
                              if (context.mounted) {
                                if (completed) {
                                  String result = roulettelist[resultInt].name;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已取消')),
                                  );
                                }
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
