import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart';

import 'package:flutter_print_demo/models/print_item.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

class PrintPage extends StatefulWidget {
  final PrintItem printItem;

  const PrintPage({required this.printItem, Key? key}) : super(key: key);

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  List<BluetoothPrinter> printers = [];

  Printer printer = Printer();
  PrinterInfo printInfo = PrinterInfo();
  bool printerSet = false;

  final printerModelName = Model.PT_P710BT;

  WidgetsToImageController controller = WidgetsToImageController();
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    try {
      initializePrinter();
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> initializePrinter() async {
    printInfo.printerModel = printerModelName;
    printInfo.printMode = PrintMode.FIT_TO_PAGE;
    // Disable cutting after every page
    printInfo.isAutoCut = false;
    // Disable end cut.
    printInfo.isCutAtEnd = false;
    // Allow for cutting mid page
    printInfo.isHalfCut = true;
    printInfo.port = Port.BLUETOOTH;
    // Set the label type.
    printInfo.labelNameIndex = PT.ordinalFromID(PT.W36.getId());

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printInfo);
    setState(() {
      printerSet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text('Select Printer'),
      ),
      body: printerSet
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  item(),
                  const Divider(),
                  printersList(),
                ],
              ),
            )
          : _loading(),
    );
  }

  Widget _loading() {
    return const Center(
      child: CupertinoActivityIndicator(
        animating: true,
      ),
    );
  }

  Widget printersList() {
    return FutureBuilder<List<BluetoothPrinter>>(
      future: printer.getBluetoothPrinters([printerModelName.getName()]),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return _loading();

          case ConnectionState.done:
            {
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              } else {
                if (snapshot.data != null) {
                  if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Device Found',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Visibility(
                            visible: snapshot.data!.isNotEmpty,
                            child: const Text(
                              'Tap on printer to print',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                return _printerTile(
                                    printer: snapshot.data![index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  return const Center(
                    child: Text(
                      'Cannot fetch devices',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              }
            }

          default:
            return _loading();
        }
      },
    );
  }

  Widget item() {
    return WidgetsToImage(
      controller: controller,
      child: ListTile(
        leading: Text(
          widget.printItem.title,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        trailing: Image.asset(widget.printItem.imageAsset),
      ),
    );
  }

  Widget _printerTile({required BluetoothPrinter printer}) {
    return ListTile(
      onTap: () => _print(),
      leading: const Icon(Icons.print),
      title: Text(
        printer.modelName,
      ),
      subtitle: Text(printer.macAddress),
    );
  }

  Future<void> _print() async {
    try {
      /// capture the widget image
      final bytes = await controller.capture();

      // Get the IP Address from the first printer found.
      printInfo.macAddress = printers.single.macAddress;
      printer.setPrinterInfo(printInfo);

      printer.printImage(await bytesToImage(bytes!));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: ${e.toString()}'),
        ),
      );
    }
  }

  Future<ui.Image> bytesToImage(Uint8List imgBytes) async {
    ui.Codec codec = await ui.instantiateImageCodec(imgBytes);
    ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }
}
