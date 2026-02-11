import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_sheets_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _spreadsheetIdController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _statusMessage = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSpreadsheetId();
  }

  Future<void> _loadSavedSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('spreadsheet_id');
    if (savedId != null) {
      setState(() {
        _spreadsheetIdController.text = savedId;
      });
    }
  }

  Future<void> _saveSpreadsheetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spreadsheet_id', id);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '抽出期間を選択',
      // 日付の文字表示を極力目立たせない設定にしたいが、標準ピッカーなので限界はある
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _statusMessage = '期間が設定されました'; // 日付はあえて表示しない
      });
    }
  }

  Future<void> _runExport() async {
    final spreadsheetId = _spreadsheetIdController.text.trim();
    if (spreadsheetId.isEmpty) {
      setState(() => _statusMessage = 'スプレッドシートIDを入力してください');
      return;
    }
    if (_selectedDateRange == null) {
      setState(() => _statusMessage = '期間を選択してください');
      return;
    }

    await _saveSpreadsheetId(spreadsheetId);

    setState(() {
      _isExporting = true;
      _statusMessage = '開始します...';
    });

    try {
      await GoogleSheetsService.exportToSheets(
        spreadsheetId: spreadsheetId,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        onStatusUpdate: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );
    } catch (e) {
      // 詳細なエラーはGoogleSheetsService内で_statusMessageに反映されますが、
      // ここでも念のためキャッチします。
      if (mounted) {
        debugPrint('Export Error details: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sheets Export')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'スプレッドシートへのエクスポート',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _spreadsheetIdController,
              decoration: const InputDecoration(
                labelText: 'スプレッドシートID',
                border: OutlineInputBorder(),
                helperText: '一度入力すると次回以降も保持されます',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('エクスポート期間を選択'),
              onPressed: _isExporting ? null : _selectDateRange,
            ),
            const SizedBox(height: 20),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText( // エラーコピー用にSelectableTextに
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isExporting ? null : _runExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('スプレッドシートへ書き出す', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
