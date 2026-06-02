// 這個檔案儲存由座標反查出的城市名稱與 TDX 縣市代碼。
// 用來支援附近搜尋時的城市判斷。

/// 反查座標後得到的城市資訊，包含顯示名稱與 TDX API 使用的縣市代碼。
class ResolvedCity {
  /// 顯示給使用者看的城市名稱。
  final String displayName;

  /// TDX Tourism API 使用的縣市代碼。
  final String tdxCityKey;

  /// 建立城市反查結果。
  ///
  /// Parameters:
  /// - displayName: 顯示給使用者看的城市名稱
  /// - tdxCityKey: TDX Tourism API 使用的縣市代碼
  const ResolvedCity({required this.displayName, required this.tdxCityKey});
}
