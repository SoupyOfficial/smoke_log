import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/log_providers.dart';
import '../widgets/add_log_form.dart';
import '../widgets/info_display.dart';
import 'log_list_screen.dart';
import '../providers/thc_content_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _updateTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _deleteLog(String logId) async {
    try {
      final logRepository = ref.read(logRepositoryProvider);
      await logRepository.deleteLog(logId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete log')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showAddLogDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Log'),
          content: const AddLogForm(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomePage(BuildContext context) {
    final logsAsyncValue = ref.watch(logsStreamProvider);

    return logsAsyncValue.when(
      data: (logs) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final liveThcAsync = ref.watch(liveThcContentProvider);
                  return liveThcAsync.when(
                    data: (liveThc) => Column(
                      children: [
                        InfoDisplay(logs: logs, liveThcContent: liveThc),
                        const AddLogForm(),
                      ],
                    ),
                    loading: () => Column(
                      children: [
                        InfoDisplay(logs: logs),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                        const AddLogForm(),
                      ],
                    ),
                    error: (error, stack) => Column(
                      children: [
                        InfoDisplay(logs: logs),
                        Text('Error: $error'),
                        const AddLogForm(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _buildHomePage(context),
      const LogListScreen(),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Smoke Log'),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Logs',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddLogDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
