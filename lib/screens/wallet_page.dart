import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../services/haptic_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _walletService = WalletService();
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  RealtimeChannel? _walletChannel;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _subscribeToWalletUpdates();
  }

  @override
  void dispose() {
    _walletChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Force fresh data from server
      final wallet = await _walletService.getWallet();
      final transactions = await _walletService.getTransactionHistory(
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _wallet = wallet;
          _transactions = transactions;
          _isLoading = false;
        });
        print('✅ Wallet data loaded: Balance = ${wallet?.balance}');
      }
    } catch (e) {
      print('❌ Error loading wallet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadWalletData,
            ),
          ),
        );
      }
    }
  }

  void _subscribeToWalletUpdates() {
    try {
      _walletChannel = _walletService.subscribeToWallet((updatedWallet) {
        if (mounted) {
          setState(() {
            _wallet = updatedWallet;
          });
          // Reload transactions after wallet update
          _loadTransactions();
        }
      });
    } catch (e) {
      print('⚠️ Could not subscribe to wallet updates: $e');
      // Not critical, user can still use wallet without real-time updates
    }
  }

  Future<void> _loadTransactions() async {
    final transactions = await _walletService.getTransactionHistory(limit: 20);
    if (mounted) {
      setState(() => _transactions = transactions);
    }
  }

  void _showTopUpDialog() {
    HapticService.modalOpen();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter amount to add to your wallet:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₱',
                border: OutlineInputBorder(),
                hintText: '0.00',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a demo wallet. No real payment required.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amountText = amountController.text.trim();
              if (amountText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an amount')),
                );
                return;
              }

              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              if (amount > 100000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maximum top-up is ₱100,000')),
                );
                return;
              }

              // Close dialog immediately
              Navigator.pop(context);

              if (!mounted) return;

              // Process top-up in background
              _walletService.topUpWallet(amount);

              // Reload page immediately
              await _loadWalletData();
            },
            child: const Text('Top Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PasaPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallet == null
          ? _buildNoWalletView()
          : _buildWalletView(),
    );
  }

  Widget _buildNoWalletView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Wallet Setup Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please execute the wallet schema in Supabase first',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Setup Instructions:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Open Supabase Dashboard\n'
                    '2. Go to SQL Editor\n'
                    '3. Copy supabase_wallet_schema.sql\n'
                    '4. Paste and click "Run"\n'
                    '5. Restart the app',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWalletData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletView() {
    return RefreshIndicator(
      onRefresh: _loadWalletData,
      child: CustomScrollView(
        slivers: [
          // Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white.withOpacity(0.7),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _wallet!.formattedBalance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _showTopUpDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Top Up Wallet'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(
                        icon: Icons.arrow_upward,
                        label: 'Total Top-ups',
                        value: _transactions
                            .where(
                              (t) => t.transactionType == TransactionType.topUp,
                            )
                            .length
                            .toString(),
                        color: Colors.green,
                      ),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _buildQuickStat(
                        icon: Icons.arrow_downward,
                        label: 'Total Payments',
                        value: _transactions
                            .where(
                              (t) =>
                                  t.transactionType == TransactionType.payment,
                            )
                            .length
                            .toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Transaction History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_transactions.isNotEmpty)
                    Text(
                      '${_transactions.length} transactions',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),

          // Transaction List
          _transactions.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Top up your wallet to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = _transactions[index];
                    return _buildTransactionTile(transaction);
                  }, childCount: _transactions.length),
                ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTransactionTile(WalletTransaction transaction) {
    final isCredit = transaction.transactionType.isCredit;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = _getTransactionIcon(transaction.transactionType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction.transactionType.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null)
              Text(
                transaction.description!,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 2),
            Text(
              '${transaction.formattedDate} • ${transaction.formattedTime}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.formattedAmount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Bal: ${transaction.balanceAfter.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: transaction.description != null,
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.topUp:
        return Icons.add_circle;
      case TransactionType.payment:
        return Icons.shopping_cart;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.earning:
        return Icons.monetization_on;
      case TransactionType.withdrawal:
        return Icons.remove_circle;
    }
  }
}
