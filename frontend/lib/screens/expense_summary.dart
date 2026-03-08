import 'package:flutter/material.dart';
import '../services/bill_service.dart';
import '../components/header.dart';
import '../components/initial_avatar.dart';

class ExpenseSummaryPage extends StatefulWidget {
  final String groupId;
  final List<Map<String, String>> members;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String? paidBy;
  final String? billName;

  const ExpenseSummaryPage({
    super.key,
    required this.groupId,
    required this.members,
    required this.items,
    required this.totalAmount,
    required this.paidBy,
    this.billName,
  });

  @override
  State<ExpenseSummaryPage> createState() => _ExpenseSummaryPageState();
}

class _ExpenseSummaryPageState extends State<ExpenseSummaryPage> {
  Map<String, double> _memberAmounts = {};
  Map<String, List<Map<String, dynamic>>> _memberItems = {};

  @override
  void initState() {
    super.initState();
    _calculateMemberAmounts();
  }

  void _calculateMemberAmounts() {
    _memberAmounts.clear();
    _memberItems.clear();

    // Initialize all members with 0 amount
    for (var member in widget.members) {
      _memberAmounts[member['email']!] = 0.0;
      _memberItems[member['email']!] = [];
    }

    // Calculate amounts for each item
    for (var item in widget.items) {
      final itemPrice = item['price'] as double;
      final itemQuantity = item['quantity'] as int;
      final memberQuantities = item['memberQuantities'] as Map<String, int>;
      final distributionMethod = item['distributionMethod'] as String? ?? 'Equally';

      if (distributionMethod == 'Equally') {
        // For equally distributed items, split price equally among members
        final selectedMembers = item['takenBy'] as List<String>;
        final memberCount = selectedMembers.length;
        
        if (memberCount > 0) {
          final amountPerMember = itemPrice / memberCount;
          
          for (var memberEmail in selectedMembers) {
            _memberAmounts[memberEmail] = (_memberAmounts[memberEmail] ?? 0.0) + amountPerMember;
            _memberItems[memberEmail]!.add({
              'name': item['name'],
              'quantity': memberQuantities[memberEmail] ?? 0,
              'amount': amountPerMember,
              'totalQuantity': itemQuantity,
              'totalPrice': itemPrice,
            });
          }
        }
      } else {
        // For by quantity items, calculate based on individual quantities
        for (var entry in memberQuantities.entries) {
          final memberEmail = entry.key;
          final memberQuantity = entry.value;
          
          if (memberQuantity > 0) {
            final amountPerUnit = itemPrice / itemQuantity;
            final memberAmount = amountPerUnit * memberQuantity;
            
            _memberAmounts[memberEmail] = (_memberAmounts[memberEmail] ?? 0.0) + memberAmount;
            _memberItems[memberEmail]!.add({
              'name': item['name'],
              'quantity': memberQuantity,
              'amount': memberAmount,
              'totalQuantity': itemQuantity,
              'totalPrice': itemPrice,
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final isDark = theme.brightness == Brightness.dark;

    // Get paid by member info
    final paidByMember = widget.members.firstWhere(
      (member) => member['email'] == widget.paidBy,
      orElse: () => {'name': 'Unknown', 'email': '', 'avatar': ''},
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Header(
            title: 'Expense Summary',
            heightFactor: 0.12,
          ),
          if ((widget.billName ?? '').isNotEmpty) Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: theme.primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.billName!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Amount Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '₹ ${widget.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InitialAvatar(name: paidByMember['name'] ?? 'User', radius: 16),
                              SizedBox(width: 8),
                              Text(
                                'Paid by ${paidByMember['name']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Members Summary
                    Text(
                      'Member Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Member Cards
                    ...widget.members.map((member) {
                      final email = member['email']!;
                      final memberAmount = _memberAmounts[email] ?? 0.0;
                      final memberItemList = _memberItems[email] ?? [];

                      if (memberAmount == 0.0) return SizedBox.shrink();

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Member Header
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  InitialAvatar(name: member['name']!, radius: 24),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member['name']!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '${memberItemList.length} item${memberItemList.length != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textColor.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹ ${memberAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Items List
                            if (memberItemList.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: memberItemList.map((item) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 12),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Qty: ${item['quantity']}/${item['totalQuantity']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textColor.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹ ${item['amount'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),

                    SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: () async {
            // Map item assignedTo using member emails -> ids
            final items = widget.items.map((it) {
              final mapped = {
                'name': it['name'],
                'quantity': it['quantity'],
                'price': it['price'],
              };
              final takenByEmails = (it['takenBy'] as List?)?.cast<String>() ?? [];
              final assignedToIds = widget.members
                  .where((m) => takenByEmails.contains(m['email']))
                  .map((m) => m['id']!)
                  .toList();
              if (assignedToIds.isNotEmpty) mapped['assignedTo'] = assignedToIds;
              return mapped;
            }).toList();

            final billName = (widget.billName ?? 'Manual Expense').trim();
            final totalAmount = widget.totalAmount;

            // Resolve payer id
            String? payerId;
            if (widget.paidBy != null && widget.paidBy!.isNotEmpty) {
              payerId = widget.members
                  .firstWhere((m) => m['email'] == widget.paidBy, orElse: () => {'id': ''})['id'];
            }

            // Payments array
            final payments = <Map<String, dynamic>>[];
            if (payerId != null && payerId.isNotEmpty) {
              payments.add({
                'user': payerId,
                'amount': totalAmount,
              });
            }

            // Assignments based on per-item member amounts
            final assignments = <Map<String, dynamic>>[];
            if (payerId != null && payerId.isNotEmpty) {
              widget.members.forEach((member) {
                final email = member['email']!;
                final userId = member['id']!;
                final owed = _memberAmounts[email] ?? 0.0;
                if (owed > 0 && userId != payerId) {
                  assignments.add({
                    'from': userId,
                    'to': payerId,
                    'amount': double.parse(owed.toStringAsFixed(2)),
                  });
                }
              });
            }

            final res = await BillService.createManualExpense(
              groupId: widget.groupId,
              totalAmount: totalAmount,
              items: items,
              billName: billName.isNotEmpty ? billName : 'Manual Expense',
              splitMethod: 'per-item',
              payments: payments,
              assignments: assignments,
            );

            if (mounted) {
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Failed to create expense'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Text(
            'Confirm & Add Expense',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
