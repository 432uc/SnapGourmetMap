import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/photo_spot.dart';
import '../helpers/db_helper.dart';

class GoogleSheetsService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      sheets.SheetsApi.spreadsheetsScope,
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<bool> isUserSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  static Future<void> exportToSheets({
    required String spreadsheetId,
    required DateTime startDate,
    required DateTime endDate,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google Sign-In failed');

      final httpClient = (await _googleSignIn.authenticatedClient())!;
      final sheetsApi = sheets.SheetsApi(httpClient);

      // 1. データの取得とフィルタリング
      onStatusUpdate?.call('データを読み込み中...');
      final filteredSpots = await DBHelper.searchSpots(
        startDate: startDate,
        endDate: endDate.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)), // その日の23:59:59まで
      );
      
      if (filteredSpots.isEmpty) {
        throw Exception('指定された期間のデータが見つかりませんでした。');
      }

      // スプレッドシートの情報を取得して、最初のシート名を確認する
      onStatusUpdate?.call('シート情報を確認中...');
      final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
      final firstSheetTitle = spreadsheet.sheets?.first.properties?.title ?? 'Sheet1';

      // 最初の行を確認して、空ならヘッダーを追加する
      onStatusUpdate?.call('ヘッダーを確認中...');
      final response = await sheetsApi.spreadsheets.values.get(spreadsheetId, '$firstSheetTitle!A1:A1');
      final bool isSheetEmpty = response.values == null || response.values!.isEmpty;
      
      // カテゴリとサブカテゴリのマスターデータを取得
      final categoriesData = await DBHelper.getData('categories');
      final subCategoriesData = await DBHelper.getData('sub_categories');
      
      final Map<int, String> categoryMap = {
        for (var item in categoriesData) item['id'] as int: item['name'] as String
      };
      final Map<int, String> subCategoryMap = {
        for (var item in subCategoriesData) item['id'] as int: item['name'] as String
      };

      // 値のリストを作成
      List<List<Object>> values = [];

      if (isSheetEmpty) {
        values.add(['店名', '訪問日', '訪問回数', 'カテゴリー', 'サブカテゴリー', '評価', 'オーダー内容', 'メモ', '緯度', '経度']);
      }

      values.addAll(filteredSpots.map((spot) {
        // オーダー内容を文字列に結合 (例: "ラーメン (¥800), 餃子 (¥400)")
        final ordersString = spot.orders.map((o) => '${o.itemName}${o.price != null ? ' (¥${o.price})' : ''}').join(', ');
        
        return [
          spot.shopName ?? '',
          spot.visitDate.toIso8601String().split('T')[0], // 訪問日
          spot.visitCount ?? '', // 訪問回数
          categoryMap[spot.categoryId] ?? '', // カテゴリー名
          subCategoryMap[spot.subCategoryId] ?? '', // サブカテゴリー名
          '★' * (spot.rating ?? 0), // 味（評価）
          ordersString, // オーダー内容
          spot.notes ?? '', // メモ
          spot.latitude?.toString() ?? '',
          spot.longitude?.toString() ?? '',
        ];
      }));

      // スプレッドシートへ追記
      onStatusUpdate?.call('スプレッドシートに書き込み中...');
      final valueRange = sheets.ValueRange.fromJson({
        'values': values,
      });

      // シート名を自動取得したものに差し替え
      await sheetsApi.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        '$firstSheetTitle!A1', 
        valueInputOption: 'USER_ENTERED',
      );

      onStatusUpdate?.call('エクスポート完了！');
    } catch (e, stack) {
      debugPrint('Export Error: $e');
      debugPrint('Stack Trace: $stack');
      
      String errorMsg = e.toString();
      if (errorMsg.contains('404')) {
        errorMsg = 'スプレッドシートが見つかりません。IDが正しいか確認してください。';
      } else if (errorMsg.contains('403')) {
        errorMsg = 'アクセス権限がありません。スプレッドシートの共有設定を確認してください。';
      }
      
      onStatusUpdate?.call('エラー: $errorMsg');
      rethrow;
    }
  }
}
