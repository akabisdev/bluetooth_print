import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter_print_demo/models/print_item.dart';

class PrintPage extends StatefulWidget {
  final PrintItem printItem;

  const PrintPage({required this.printItem, Key? key}) : super(key: key);

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'No device connected';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected ?? false;

    bluetoothPrint.state.listen((state) {
      print('******************* cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text('Select Printer'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            bluetoothPrint.startScan(timeout: const Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: Text(tips),
                  ),
                ],
              ),
              const Divider(),
              StreamBuilder<List<BluetoothDevice>>(
                stream: bluetoothPrint.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                            title: Text(d.name ?? ''),
                            subtitle: Text(d.address ?? ''),
                            onTap: () async {
                              setState(() {
                                _device = d;
                              });
                            },
                            trailing:
                                _device != null && _device!.address == d.address
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                          ))
                      .toList(),
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: _connected
                              ? null
                              : () async {
                                  if (_device != null &&
                                      _device!.address != null) {
                                    setState(() {
                                      tips = 'connecting...';
                                    });
                                    await bluetoothPrint.connect(_device!);
                                  } else {
                                    setState(() {
                                      tips = 'please select device';
                                    });
                                    print('please select device');
                                  }
                                },
                          child: const Text('connect'),
                        ),
                        const SizedBox(width: 10.0),
                        OutlinedButton(
                          onPressed: _connected
                              ? () async {
                                  setState(() {
                                    tips = 'disconnecting...';
                                  });
                                  await bluetoothPrint.disconnect();
                                }
                              : null,
                          child: const Text('disconnect'),
                        ),
                      ],
                    ),
                    const Divider(),
                    // OutlinedButton(
                    //   child: Text('print receipt(esc)'),
                    //   onPressed: _connected
                    //       ? () async {
                    //           Map<String, dynamic> config = Map();
                    //           List<LineText> list = [];
                    //
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content:
                    //                   '**********************************************',
                    //               weight: 1,
                    //               align: LineText.ALIGN_CENTER,
                    //               linefeed: 1));
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '打印单据头',
                    //               weight: 1,
                    //               align: LineText.ALIGN_CENTER,
                    //               fontZoom: 2,
                    //               linefeed: 1));
                    //           list.add(LineText(linefeed: 1));
                    //
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '物资名称规格型号',
                    //               align: LineText.ALIGN_LEFT,
                    //               absolutePos: 0,
                    //               relativePos: 0,
                    //               linefeed: 0));
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '单位',
                    //               align: LineText.ALIGN_LEFT,
                    //               absolutePos: 350,
                    //               relativePos: 0,
                    //               linefeed: 0));
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '数量',
                    //               align: LineText.ALIGN_LEFT,
                    //               absolutePos: 500,
                    //               relativePos: 0,
                    //               linefeed: 1));
                    //
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '混凝土C30',
                    //               align: LineText.ALIGN_LEFT,
                    //               absolutePos: 0,
                    //               relativePos: 0,
                    //               linefeed: 0));
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '吨',
                    //               align: LineText.ALIGN_LEFT,
                    //               absolutePos: 350,
                    //               relativePos: 0,
                    //               linefeed: 0));
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content: '12.0',
                    //               align: LineText.ALIGN_LEFT,
                    //               absolutePos: 500,
                    //               relativePos: 0,
                    //               linefeed: 1));
                    //
                    //           list.add(LineText(
                    //               type: LineText.TYPE_TEXT,
                    //               content:
                    //                   '**********************************************',
                    //               weight: 1,
                    //               align: LineText.ALIGN_CENTER,
                    //               linefeed: 1));
                    //           list.add(LineText(linefeed: 1));
                    //
                    //           ByteData data = await rootBundle
                    //               .load("assets/images/bluetooth_print.png");
                    //           List<int> imageBytes = data.buffer.asUint8List(
                    //               data.offsetInBytes, data.lengthInBytes);
                    //           String base64Image = base64Encode(imageBytes);
                    //           // list.add(LineText(type: LineText.TYPE_IMAGE, content: base64Image, align: LineText.ALIGN_CENTER, linefeed: 1));
                    //
                    //           await bluetoothPrint.printReceipt(config, list);
                    //         }
                    //       : null,
                    // ),
                    OutlinedButton(
                      onPressed: _connected
                          ? () async {
                              Map<String, dynamic> config = {};

                              List<LineText> list = [];
                              list.add(
                                LineText(
                                  type: LineText.TYPE_TEXT,
                                  content: widget.printItem.title,
                                  size: 14,
                                  align: LineText.ALIGN_LEFT,
                                ),
                              );
                              ByteData data = await rootBundle
                                  .load(widget.printItem.imageAsset);
                              List<int> imageBytes = data.buffer.asUint8List(
                                  data.offsetInBytes, data.lengthInBytes);
                              String base64Image = base64Encode(imageBytes);
                              list.add(
                                LineText(
                                  type: LineText.TYPE_IMAGE,
                                  content: base64Image,
                                  align: LineText.ALIGN_RIGHT,
                                ),
                              );

                              try {
                                await bluetoothPrint.printLabel(config, list);
                              } on Exception catch (e) {
                                print(e.toString());
                              }
                            }
                          : null,
                      child: const Text('Print'),
                    ),
                    // OutlinedButton(
                    //   child: const Text('print selftest'),
                    //   onPressed: _connected
                    //       ? () async {
                    //           await bluetoothPrint.printTest();
                    //         }
                    //       : null,
                    // )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bluetoothPrint.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.hasError) {
            print('Error FAB: ${snapshot.error.toString()}');
          }
          if (snapshot.data == true) {
            return FloatingActionButton(
              onPressed: () => bluetoothPrint.stopScan(),
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: () => bluetoothPrint.startScan(
                    timeout: const Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}
