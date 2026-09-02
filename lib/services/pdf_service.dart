import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class PdfService {
  static Future<void> generateOrderInvoice(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Order #${order.id.toUpperCase()}'),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(order.shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Zen Mart Pro Platform'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Billing Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.customerName),
                      pw.Text(order.customerPhone),
                      pw.Text(order.deliveryAddress),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Vendor:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(order.shopName),
                      pw.Text(order.vendorPhone),
                      pw.Text(order.pickupAddress),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Items Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Item Description', 'Qty', 'Unit Price', 'Total'],
                data: order.items.map((item) {
                  return [
                    item['name'],
                    item['quantity'].toString(),
                    'Rs ${item['price']}',
                    'Rs ${item['price'] * item['quantity']}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: Rs ${order.totalAmount - order.deliveryFee}'),
                    pw.Text('Delivery Fee: Rs ${order.deliveryFee}'),
                    pw.Divider(),
                    pw.Text(
                      'Grand Total: Rs ${order.totalAmount}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for shopping with Zen Mart Pro!')),
              pw.Center(child: pw.Text('Powered by Zenvyro Labs', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order.id}',
    );
  }

  static Future<void> generateFinancialReport({
    required double daily,
    required double weekly,
    required double monthly,
    required double commission,
    required double deliveryFees,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Zen Mart Pro Financial Audit', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('MMMM yyyy').format(DateTime.now())),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text('Revenue Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Period', 'Revenue (Rs)'],
                data: [
                  ['Daily Revenue', NumberFormat('#,###').format(daily)],
                  ['Weekly Revenue', NumberFormat('#,###').format(weekly)],
                  ['Monthly Revenue', NumberFormat('#,###').format(monthly)],
                ],
              ),
              
              pw.SizedBox(height: 40),
              pw.Text('Platform Earnings Distribution', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Stream', 'Amount (Rs)', 'Percentage'],
                data: [
                  ['Vendor Net Sales', NumberFormat('#,###').format(monthly - commission - deliveryFees), '70%'],
                  ['Platform Commission', NumberFormat('#,###').format(commission), '20%'],
                  ['Delivery & Service Fees', NumberFormat('#,###').format(deliveryFees), '10%'],
                ],
              ),

              pw.SizedBox(height: 40),
              pw.Text('Compliance & Verification', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'All transactions are audited via Firestore Ledger.'),
              pw.Bullet(text: 'Net platform earnings are calculated after tax deductions.'),
              pw.Bullet(text: 'Report generated by Super Admin credentials.'),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(child: pw.Text('Confidential Financial Document - Zen Mart Pro', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Financial_Report_${DateFormat('yyyyMM').format(DateTime.now())}',
    );
  }

  static Future<void> generateUserGrowthReport({
    required int totalCustomers,
    required int totalVendors,
    required int totalRiders,
    required List<Map<String, dynamic>> monthlyStats,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Zen Mart Pro - User Growth Analysis', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _statBox('CUSTOMERS', totalCustomers.toString()),
                  _statBox('VENDORS', totalVendors.toString()),
                  _statBox('RIDERS', totalRiders.toString()),
                ],
              ),
              pw.SizedBox(height: 40),

              pw.Text('Monthly Acquisition Trends', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Month', 'New Users', 'Growth %'],
                data: monthlyStats.map((s) => [s['month'], s['count'].toString(), s['growth']]).toList(),
              ),

              pw.Spacer(),
              pw.Text('Note: Growth percentage is relative to previous audit cycle.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              pw.Divider(),
              pw.Align(alignment: pw.Alignment.center, child: pw.Text('Generated by Platform Analytics Engine', style: pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'User_Growth_${DateFormat('yyyy').format(DateTime.now())}',
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static Future<void> generatePlatformReport({
    required int totalShops,
    required int totalRiders,
    required int totalCustomers,
    required double monthlyRevenue,
    required int pendingOrders,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Zen Mart Pro Platform Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              pw.Text('Performance Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: ['Metric', 'Current Value'],
                data: [
                  ['Total Registered Shops', totalShops.toString()],
                  ['Active Delivery Riders', totalRiders.toString()],
                  ['Total Customers', totalCustomers.toString()],
                  ['Monthly Revenue', 'Rs ${NumberFormat.compact().format(monthlyRevenue)}'],
                  ['Orders Awaiting Action', pendingOrders.toString()],
                ],
              ),
              
              pw.SizedBox(height: 40),
              pw.Text('Report Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Platform growth is monitored on a weekly basis.'),
              pw.Bullet(text: 'Revenue figures include commissions and delivery surcharges.'),
              pw.Bullet(text: 'This report is for internal administrative use only.'),

              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Authorized by Super Admin Control Panel', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Platform_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static Future<void> generateRiderEarningsReport(UserModel rider, List<OrderModel> history) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Earnings Statement', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rider: ${rider.name}'),
              pw.Text('ID: ${rider.uid.toUpperCase()}'),
              pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
              pw.SizedBox(height: 30),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Lifetime Deliveries', style: pw.TextStyle(color: PdfColors.grey)),
                      pw.Text(rider.totalDeliveries.toString(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Earnings', style: pw.TextStyle(color: PdfColors.grey)),
                      pw.Text('Rs ${rider.totalEarnings.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              pw.Text('Recent Activity', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Order ID', 'Date', 'Shop', 'Earning'],
                data: history.take(20).map((o) {
                  return [
                    o.id.substring(0, 8).toUpperCase(),
                    DateFormat('dd/MM/yy').format(o.deliveredAt ?? o.createdAt),
                    o.shopName,
                    'Rs ${o.deliveryFee.toStringAsFixed(0)}',
                  ];
                }).toList(),
              ),

              pw.Spacer(),
              pw.Center(child: pw.Text('This is a computer generated statement.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Earnings_${rider.name}_${DateFormat('yyyyMM').format(DateTime.now())}',
    );
  }
}
