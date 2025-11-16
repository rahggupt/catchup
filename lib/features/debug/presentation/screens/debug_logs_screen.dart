import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/services/logger_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DebugLogsScreen extends StatefulWidget {
  const DebugLogsScreen({super.key});

  @override
  State<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends State<DebugLogsScreen> {
  final LoggerService _logger = LoggerService();
  String _selectedLevel = 'All';
  String _selectedCategory = 'All';
  
  List<String> get _availableCategories {
    final categories = _logger.logs.map((log) => log.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  List<LogEntry> get _filteredLogs {
    var logs = _logger.logs;
    
    if (_selectedLevel != 'All') {
      logs = logs.where((log) => log.level == _selectedLevel).toList();
    }
    
    if (_selectedCategory != 'All') {
      logs = logs.where((log) => log.category == _selectedCategory).toList();
    }
    
    return logs.reversed.toList(); // Show newest first
  }

  @override
  Widget build(BuildContext context) {
    final summary = _logger.getLogSummary();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadLogs,
            tooltip: 'Download Logs',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLogs,
            tooltip: 'Share Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard('Info', summary[LoggerService.levelInfo] ?? 0, Colors.blue),
                    _buildSummaryCard('Warning', summary[LoggerService.levelWarning] ?? 0, Colors.orange),
                    _buildSummaryCard('Error', summary[LoggerService.levelError] ?? 0, Colors.red),
                    _buildSummaryCard('Debug', summary[LoggerService.levelDebug] ?? 0, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['All', LoggerService.levelInfo, LoggerService.levelWarning, 
                            LoggerService.levelError, LoggerService.levelDebug, LoggerService.levelSuccess]
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLevel = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _availableCategories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Log list
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No logs available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredLogs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return _buildLogItem(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(LogEntry log) {
    Color levelColor;
    IconData levelIcon;
    
    switch (log.level) {
      case LoggerService.levelInfo:
        levelColor = Colors.blue;
        levelIcon = Icons.info_outline;
        break;
      case LoggerService.levelWarning:
        levelColor = Colors.orange;
        levelIcon = Icons.warning_amber;
        break;
      case LoggerService.levelError:
        levelColor = Colors.red;
        levelIcon = Icons.error_outline;
        break;
      case LoggerService.levelDebug:
        levelColor = Colors.purple;
        levelIcon = Icons.bug_report;
        break;
      case LoggerService.levelSuccess:
        levelColor = Colors.green;
        levelIcon = Icons.check_circle_outline;
        break;
      default:
        levelColor = Colors.grey;
        levelIcon = Icons.circle;
    }
    
    return ExpansionTile(
      leading: Icon(levelIcon, color: levelColor),
      title: Text(
        log.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${log.timestamp.toLocal().toString().substring(0, 19)} • ${log.category}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full Message:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                log.message,
                style: const TextStyle(fontSize: 13),
              ),
              if (log.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Error:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  log.error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[900],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (log.stackTrace != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Stack Trace:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.stackTrace!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: log.format()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Log copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadLogs() async {
    try {
      final logsContent = _logger.exportLogs();
      final fileName = 'catchup_logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt';
      
      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      // Write file
      await file.writeAsString(logsContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs saved to: ${file.path}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareLogs() async {
    try {
      final logsContent = _logger.exportLogs();
      final fileName = 'catchup_logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt';
      
      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(logsContent);
      
      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'CatchUp Debug Logs',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('This will delete all logged entries. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _logger.clearLogs();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All logs cleared'),
          ),
        );
      }
    }
  }
}

