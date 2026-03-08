import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/header.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../services/invite_service.dart';
import 'add_bill.dart';
import 'members.dart';
import 'dart:convert';
import '../components/loading_dialog.dart';
import '../services/get_bills.dart';
import '../services/bill_service.dart';
import '../services/delete_bill.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  const GroupDetailsPage({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  bool _isLoading = true;
  String _groupName = 'Group';
  String _groupDescription = '';
  List<Map<String, String>> _members = [];
  String? _currentUserEmail;
  String? _adminEmail;
  String? _adminName;
  bool _isCurrentUserAdmin = false;
  late GroupService _groupService;
  List<Map<String, dynamic>> _billAssignments = [];
  List<Map<String, dynamic>> _bills = [];

  @override
  void initState() {
    super.initState();
    _groupService = Provider.of<GroupService>(context, listen: false);
    print('🧭 GroupDetailsPage.initState for group: ${widget.groupId}');
    _loadGroupDetails();
    _loadBillAssignments();
    _loadBills();
  }

  Future<void> _loadGroupDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = await AuthService.getProfile();
      _currentUserEmail = currentUser?.email ?? '';
      
      print('👤 Current user email: $_currentUserEmail');
      
      final groupData = await _groupService.fetchGroupDetails(widget.groupId);
      
      if (groupData != null && mounted) {
        // 🔍 DEBUG: Print EXACT response structure
        print('╔════════════════════════════════════════╗');
        print('🔍 RAW GROUP DATA:');
        print(jsonEncode(groupData));
        print('╚════════════════════════════════════════╝');
        
        // Print members specifically
        final membersList = groupData['members'];
        print('👥 Members field type: ${membersList.runtimeType}');
        print('👥 Members content: $membersList');
        
        if (membersList is List) {
          print('👥 Member count: ${membersList.length}');
          for (int i = 0; i < membersList.length; i++) {
            final member = membersList[i];
            print('   [$i] Type: ${member.runtimeType}');
            print('   [$i] Content: $member');
            if (member is Map) {
              print('   [$i] Keys: ${member.keys}');
              print('   [$i] _id: ${member['_id']}');
              print('   [$i] name: ${member['name']}');
              print('   [$i] email: ${member['email']}');
            }
          }
        }
        print('╚════════════════════════════════════════╝');
        
        // Extract admin information
        final createdByField = groupData['createdBy'];
        String? adminId;
        
        if (createdByField is Map) {
          _adminEmail = createdByField['email']?.toString();
          _adminName = createdByField['name']?.toString();
          adminId = createdByField['_id']?.toString() ?? createdByField['id']?.toString();
        } else if (createdByField is String) {
          adminId = createdByField;
        }

        print('👑 Admin ID: $adminId, Name: $_adminName, Email: $_adminEmail');

        // Check if current user is admin
        _isCurrentUserAdmin = (_adminEmail != null && _adminEmail == _currentUserEmail);

        // Extract members
        _members.clear();
        
        if (membersList is List && membersList.isNotEmpty) {
          print('👥 Processing ${membersList.length} members from group...');
          
          for (final member in membersList) {
            if (member is Map) {
              final memberId = member['_id']?.toString() ?? member['id']?.toString() ?? '';
              final memberName = member['name']?.toString() ?? 'Member';
              final memberEmail = member['email']?.toString() ?? '';
              
              print('   Processing: $memberName');
              print('      ID: $memberId');
              print('      Email: $memberEmail');
              
              if (memberId.isNotEmpty && memberId != 'null') {
                // Generate consistent avatar
                final avatarId = memberEmail.isNotEmpty 
                    ? (memberEmail.hashCode.abs() % 70) + 1
                    : (memberId.hashCode.abs() % 70) + 1;
                
                final isAdmin = (memberId == adminId) || (memberEmail == _adminEmail && memberEmail.isNotEmpty);
                final isCurrentUser = (memberEmail == _currentUserEmail && memberEmail.isNotEmpty);
                
                _members.add({
                  'id': memberId,
                  'name': memberName,
                  'email': memberEmail,
                  'avatar': 'https://i.pravatar.cc/150?img=$avatarId',
                  'isCurrentUser': isCurrentUser ? 'true' : 'false',
                  'isAdmin': isAdmin ? 'true' : 'false',
                });
                
                print('   ✅ Added: $memberName (ID: $memberId)');
              }
            } else if (member is String) {
              print('   ⚠️ Member is just an ID string: $member');
              print('   ⚠️ Backend did not populate members. This will cause issues.');
            }
          }
        }
        
        // If members list is empty, show error
        if (_members.isEmpty) {
          throw Exception('No valid members found. The backend must populate member details in /group/get/:id endpoint.');
        }
        
        print('📋 Final members: ${_members.length}');
        for (var m in _members) {
          print('   - ${m['name']}: ID=${m['id']}, Email=${m['email']}');
        }
        
        // Set other group details
        setState(() {
          _groupName = groupData['name']?.toString() ?? 'Group';
          _groupDescription = groupData['description']?.toString() ?? '';
          _isLoading = false;
        });
        
        print('✅ Group loaded: $_groupName');
      } else {
        throw Exception('Failed to load group data');
      }
    } catch (e) {
      print('❌ Error loading group details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadBillAssignments() async {
    try {
      print('🔄 _loadBillAssignments() called');
      final data = await GetBillsService.getAssignmentsForGroup();
      print('🔄 _loadBillAssignments received ${data.length} items');
      if (mounted) {
        setState(() => _billAssignments = data);
      }
    } catch (e) {
      print('❌ Error loading bill assignments: $e');
    }
  }

  Future<void> _loadBills() async {
    try {
      print('🔄 _loadBills() called for group ${widget.groupId}');
      final data = await GetBillsService.getAllBills(groupId: widget.groupId);
      print('📥 _loadBills received ${data.length} bills');
      if (mounted) {
        setState(() => _bills = data);
      }
    } catch (e) {
      print('❌ Error loading bills: $e');
    }
  }

  void _showInviteDialog() {
    // Only admins can invite
    if (!_isCurrentUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Only the group admin can invite members')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final TextEditingController emailController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.person_add, color: theme.primaryColor),
              SizedBox(width: 12),
              Text('Invite Member'),
            ],
          ),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'Enter email address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter an email'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                // Show loading
                LoadingDialog.show(
                  context: context,
                  title: 'Sending Invite',
                  subtitle: 'Inviting $email to join the group...',
                  icon: Icons.send,
                  primaryColor: theme.primaryColor,
                );

                try {
                  final result = await InviteService.sendInvite(
                    groupId: widget.groupId,
                    friendEmail: email,
                  );

                  LoadingDialog.hide(context); // Close loading

                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(child: Text('Invite sent successfully!')),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Failed to send invite'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  LoadingDialog.hide(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Send Invite'),
            ),
          ],
        );
      },
    );
  }

  void _showBillDetailsModal(Map<String, dynamic> bill, ThemeData theme, Color textColor, Color cardColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final createdBy = bill['createdBy'] ?? {};
        final createdByEmail = createdBy is Map ? (createdBy['email']?.toString() ?? '') : '';
        final billName = bill['billName']?.toString() ?? 'Bill';
        final totalAmount = (bill['totalAmount'] ?? 0).toString();
        final splitMethod = bill['splitMethod']?.toString() ?? '';
        final createdAt = bill['createdAt']?.toString() ?? '';
        final items = (bill['items'] as List?) ?? [];
        final assignments = (bill['assignments'] as List?) ?? [];
        final expenseId = bill['_id']?.toString() ?? bill['id']?.toString() ?? '';
        final canDelete = createdByEmail.isNotEmpty && createdByEmail == _currentUserEmail && expenseId.isNotEmpty;
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: theme.primaryColor, size: 26),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          billName,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('₹$totalAmount', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'By ${createdBy['name'] ?? 'Unknown'} • ${_formatDate(createdAt)} • ${splitMethod.isNotEmpty ? splitMethod : 'split'}',
                    style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 18),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        if (items.isNotEmpty) ...[
                          Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                          SizedBox(height: 12),
                          ...items.map((it) {
                            final name = it['name']?.toString() ?? 'Item';
                            final qty = (it['quantity'] ?? 0).toString();
                            final price = (it['price'] ?? 0).toString();
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor)),
                                  ),
                                  Text('Qty: $qty  ·  ₹$price', style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 16),
                        ],
                        if (assignments.isNotEmpty) ...[
                          Text('Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                          SizedBox(height: 12),
                          ...assignments.map((a) {
                            final fromName = a['from'] is Map ? (a['from']['name'] ?? 'Someone') : 'Someone';
                            final toName = a['to'] is Map ? (a['to']['name'] ?? 'Someone') : 'Someone';
                            final amount = (a['amount'] ?? 0).toString();
                            return Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.compare_arrows, size: 20, color: theme.primaryColor),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text('$fromName → $toName · ₹$amount', style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],

                        if (canDelete) ...[
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: Text('Delete Bill?'),
                                  content: Text('This action cannot be undone.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.of(dCtx).pop(true), child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              final res = await DeleteBillService.deleteBill(
                                expenseId: expenseId,
                                context: context,
                                groupId: widget.groupId,
                              );
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              if (res['success'] == true) {
                                setState(() {
                                  _bills.removeWhere((b) => (b['_id']?.toString() ?? b['id']?.toString() ?? '') == expenseId);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Bill deleted'), backgroundColor: Colors.green),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Failed to delete'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(Icons.delete),
                            label: Text('Delete Bill'),
                          ),
                        ],
                      ],
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

  // ✅ NEW: Format date helper
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // ✅ NEW: Build expense card
  Widget _buildExpenseCard({
    required Map<String, dynamic> expense,
    required Color cardColor,
    required Color textColor,
    required Color primaryColor,
    required bool isDark,
  }) {
    final totalAmount = (expense['totalAmount'] ?? 0).toDouble();
    final description = expense['description']?.toString() ?? 'Expense';
    final createdAt = expense['createdAt']?.toString() ?? '';
    final assignments = expense['assignments'] as List? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                '₹${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Display assignments
          ...assignments.map((assignment) {
            final fromName = assignment['from']?['name'] ?? 'Someone';
            final toName = assignment['to']?['name'] ?? 'Someone';
            final amount = (assignment['amount'] ?? 0).toDouble();
            final fromEmail = assignment['from']?['email'] ?? '';
            final toEmail = assignment['to']?['email'] ?? '';
            
            String displayText;
            Color displayColor;
            
            if (fromEmail == _currentUserEmail) {
              displayText = 'You owe $toName ₹${amount.toStringAsFixed(2)}';
              displayColor = Colors.red;
            } else if (toEmail == _currentUserEmail) {
              displayText = '$fromName owes you ₹${amount.toStringAsFixed(2)}';
              displayColor = Colors.green;
            } else {
              displayText = '$fromName owes $toName ₹${amount.toStringAsFixed(2)}';
              displayColor = textColor.withOpacity(0.7);
            }
            
            return Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    fromEmail == _currentUserEmail || toEmail == _currentUserEmail
                        ? Icons.arrow_forward
                        : Icons.people_outline,
                    size: 16,
                    color: displayColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 13,
                        color: displayColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (createdAt.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Header(
            title: _groupName,
            heightFactor: 0.12,
          ),
          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading group details...',
                      style: TextStyle(color: textColor.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  print('🔁 Pull-to-refresh triggered');
                  await _loadGroupDetails();
                  await _loadBillAssignments();
                  await _loadBills();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Info Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      primaryColor.withOpacity(0.2),
                                      primaryColor.withOpacity(0.05),
                                    ]
                                  : [
                                      primaryColor.withOpacity(0.15),
                                      primaryColor.withOpacity(0.05),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.groups,
                                size: 48,
                                color: primaryColor,
                              ),
                              SizedBox(height: 12),
                              Text(
                                _groupName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${_members.length} member${_members.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                              if (_groupDescription.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardColor.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _groupDescription,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.person_add,
                                label: 'Invite',
                                color: _isCurrentUserAdmin ? Colors.blue : Colors.grey,
                                onTap: _showInviteDialog,
                                cardColor: cardColor,
                                textColor: textColor,
                                isDisabled: !_isCurrentUserAdmin,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.people,
                                label: 'Members',
                                color: Colors.green,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MembersPage(
                                        groupName: _groupName,
                                        members: _members,
                                        primaryColor: primaryColor,
                                      ),
                                    ),
                                  );
                                },
                                cardColor: cardColor,
                                textColor: textColor,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Recent Activity section removed as requested

                        if (_bills.isNotEmpty) ...[
                          SizedBox(height: 24),
                          Text(
                            'Bills',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 12),
                          Column(
                            children: _bills.map((bill) {
                              final theme = Theme.of(context);
                              final billName = bill['billName']?.toString() ?? 'Bill';
                              final totalAmount = (bill['totalAmount'] ?? 0).toDouble();
                              final createdBy = bill['createdBy'];
                              final createdByEmail = createdBy is Map ? (createdBy['email']?.toString() ?? '') : '';
                              // Build owe/owed line based on assignments (moved logic from Recent Activity)
                              String subText;
                              Color subColor;
                              final assignments = (bill['assignments'] as List?) ?? [];
                              double totalOwedToYou = 0.0;
                              double totalYouOwe = 0.0;
                              for (final a in assignments) {
                                final fromEmail = a is Map ? (a['from'] is Map ? (a['from']['email']?.toString() ?? '') : '') : '';
                                final toEmail = a is Map ? (a['to'] is Map ? (a['to']['email']?.toString() ?? '') : '') : '';
                                final amount = a is Map ? ((a['amount'] ?? 0).toDouble()) : 0.0;
                                if (fromEmail == _currentUserEmail) totalYouOwe += amount;
                                if (toEmail == _currentUserEmail) totalOwedToYou += amount;
                              }
                              final net = totalOwedToYou - totalYouOwe;
                              if (net > 0.0) {
                                subText = 'You are owed ₹${net.toStringAsFixed(2)}';
                                subColor = Colors.green;
                              } else if (net < 0.0) {
                                subText = 'You owe ₹${(-net).toStringAsFixed(2)}';
                                subColor = Colors.red;
                              } else {
                                subText = 'Settled';
                                subColor = textColor.withOpacity(0.7);
                              }
                              return InkWell(
                                onTap: () => _showBillDetailsModal(bill, theme, textColor, cardColor, isDark),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.receipt_long, color: primaryColor),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              billName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: textColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${totalAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        subText,
                                        style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        if (_billAssignments.isNotEmpty) ...[
                          SizedBox(height: 24),
                          Text(
                            'Uploaded Bills',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: _billAssignments.map((a) {
                              String getMemberName(String id) {
                                final found = _members.firstWhere(
                                  (m) => m['id'] == id,
                                  orElse: () => {},
                                );
                                return found['name'] ?? id;
                              }
                              final fromId = a['from']?.toString() ?? '';
                              final toId = a['to']?.toString() ?? '';
                              final amount = a['amount']?.toString() ?? '';
                              final fromName = getMemberName(fromId);
                              final toName = getMemberName(toId);
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.white24 : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.receipt_long, color: primaryColor.withOpacity(0.65), size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'From: $fromName   To: $toName   Amount: ₹$amount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final invalidMembers = _members.where((m) => 
                  m['id'] == null || m['id']!.isEmpty || m['id'] == 'null'
                ).toList();
                
                if (invalidMembers.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Some members have invalid IDs. Cannot create bill.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                if (_members.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No members in group. Cannot create bill.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                print('🚀 Navigating to AddBillPage with ${_members.length} members');
                print('📋 Members data:');
                for (var m in _members) {
                  print('   - ${m['name']}: ID=${m['id']}');
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddBillPage(
                      groupId: widget.groupId,
                      members: _members,
                    ),
                  ),
                );
              },
              backgroundColor: primaryColor,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Bill',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    bool isDisabled = false,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? textColor.withOpacity(0.5) : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}