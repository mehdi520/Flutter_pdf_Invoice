import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nexus_related/api/pdf_api.dart';
import 'package:nexus_related/model/customer.dart';
import 'package:nexus_related/model/invoice.dart';
import 'package:nexus_related/model/supplier.dart';
import 'package:nexus_related/utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;


class BudgetcareInvoiceapi {
 static Future<Uint8List> _loadLogo() async {
    final ByteData data = await rootBundle.load('assets/images/logo2.png');
    return data.buffer.asUint8List();
  }

  static Future<File> generate(Invoice invoice) async {
    final pdf = Document();
    final Uint8List logoData = await _loadLogo();

    pdf.addPage(MultiPage(
      build: (context) => [
        buildHeader(invoice,logoData),
        SizedBox(height: 2 * PdfPageFormat.cm),
        buildTitle(invoice),
        buildInvoice(invoice),
        Divider(),
        buildTotal(invoice),
      ],
      footer: (context) => buildFooter(invoice),
    ));

    return PdfApi.saveDocument(name: 'BudgetCare_Report.pdf', pdf: pdf);
  }

  static Widget buildHeader(Invoice invoice,Uint8List logoData) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // buildSupplierAddress(invoice.supplier),
          pw.Image(
            pw.MemoryImage(logoData),
            width: 100,
            height: 100,
          ),
          Container(
            height: 50,
            width: 50,
            child: BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: "https://mehdibalti.com",
            ),
          ),
        ],
      ),
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildCustomerAddress(invoice.customer),
        ],
      ),
    ],
  );

  static Widget buildCustomerAddress(Customer customer) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('G Mehdi Balti', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('ghulammehdi178@gmail.com'),
    ],
  );

  // static Widget buildInvoiceInfo(InvoiceInfo info) {
  //   final paymentTerms = '${info.dueDate.difference(info.date).inDays} days';
  //   final titles = <String>[
  //     'Invoice Number:',
  //     'Invoice Date:',
  //     'Payment Terms:',
  //     'Due Date:'
  //   ];
  //   final data = <String>[
  //     info.number,
  //     Utils.formatDate(info.date),
  //     paymentTerms,
  //     Utils.formatDate(info.dueDate),
  //   ];
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: List.generate(titles.length, (index) {
  //       final title = titles[index];
  //       final value = data[index];
  //
  //       return buildText(title: title, value: value, width: 200);
  //     }),
  //   );
  // }

  // static Widget buildSupplierAddress(Supplier supplier) => Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //     Text(supplier.name, style: TextStyle(fontWeight: FontWeight.bold)),
  //     SizedBox(height: 1 * PdfPageFormat.mm),
  //     Text(supplier.address),
  //   ],
  // );

  static Widget buildTitle(Invoice invoice) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'INCOME DETAIL REPORT',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
      Text('Below are the income details for the Food category from August 1, 2024, to August 31, 2024.'),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
    ],
  );

  static Widget buildInvoice(Invoice invoice) {
    final headers = [
      'Date',
      'Description',
      'Amount'
    ];
    final data = invoice.items.map((item) {
      final total = item.unitPrice * item.quantity * (1 + item.vat);

      return [
        Utils.formatDate(item.date),
        item.description,
        '\$ ${total.toStringAsFixed(2)}',
      ];
    }).toList();

    return Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerRight,
        2: Alignment.centerRight,
        3: Alignment.centerRight,
        4: Alignment.centerRight,
        5: Alignment.centerRight,
      },
    );
  }

  static Widget buildTotal(Invoice invoice) {
    final netTotal = invoice.items
        .map((item) => item.unitPrice * item.quantity)
        .reduce((item1, item2) => item1 + item2);
    final vatPercent = invoice.items.first.vat;
    final vat = netTotal * vatPercent;
    final total = netTotal + vat;

    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Spacer(flex: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildText(
                  title: 'Net total',
                  value: Utils.formatPrice(netTotal),
                  unite: true,
                ),
                Divider(),
                buildText(
                  title: 'Total amount',
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  value: Utils.formatPrice(total),
                  unite: true,
                ),
                SizedBox(height: 2 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
                SizedBox(height: 0.5 * PdfPageFormat.mm),
                Container(height: 1, color: PdfColors.grey400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFooter(Invoice invoice) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Divider(),
      SizedBox(height: 2 * PdfPageFormat.mm),
      Text('Budget Care,Street 09,Blue Area, Islamabad Pakistan'),
    ],
  );

  // static buildSimpleText({
  //   required String title,
  //   required String value,
  // }) {
  //   final style = TextStyle(fontWeight: FontWeight.bold);
  //
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     crossAxisAlignment: pw.CrossAxisAlignment.end,
  //     children: [
  //       Text(title, style: style),
  //       SizedBox(width: 2 * PdfPageFormat.mm),
  //       Text(value),
  //     ],
  //   );
  // }

  static buildText({
    required String title,
    required String value,
    double width = double.infinity,
    TextStyle? titleStyle,
    bool unite = false,
  }) {
    final style = titleStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
      width: width,
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          Text(value, style: unite ? style : null),
        ],
      ),
    );
  }
}

