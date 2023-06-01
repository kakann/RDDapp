import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:rdd/objects/capturedImageList.dart';
import 'package:rdd/utlities/DBHelper.dart';
import 'package:intl/intl.dart';
import 'package:rdd/widgets/DetailedViewScreen.dart';

class MyListScreen extends StatefulWidget {
  @override
  _MyListScreenState createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  @override
  double totalKmTravelled = 0;
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Lists"),
      ),
      body: FutureBuilder<List<CapturedImageList>>(
        future: DBHelper.getCapturedImageLists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final lists = snapshot.data;

            return ListView.builder(
              itemCount: lists!.length,
              itemBuilder: (context, index) {
                final list = lists[index];

                return Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) {
                      // Remove the list from your data source.
                      setState(() {
                        DBHelper.deleteCapturedImageList(index);
                        lists.removeAt(index);
                      });

                      // Then show a snackbar.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('CapturedImageList dismissed')),
                      );
                    },
                    // Show a red background as the item is swiped away.
                    background: Container(color: Colors.red),
                    child: Card(
                      elevation: 5,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => DetailedViewScreen(
                                capturedImageList: list,
                                totalKmTravelled: totalKmTravelled),
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${list.start_locality} -> ${list.end_locality}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'Date of Drive: ${DateFormat("yyMMdd").format(list.date)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Damages Found: ${list.getTotalDamages()}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Navigate to detail view
                                    },
                                    child: Text('Detailed View'),
                                  ),
                                  Spacer(),
                                  FutureBuilder<double>(
                                    future: list.calculateTotalDistance(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<double> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        totalKmTravelled = snapshot.data!;
                                        return Text(
                                            'Km: ${snapshot.data?.toStringAsFixed(2)}');
                                      }
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ));
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
