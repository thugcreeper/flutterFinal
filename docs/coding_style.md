## Coding Style

Prefer existing project patterns.

---

## 1. Code Reuse Rules

Before creating any new class or file:

1. Search for existing implementations.
2. Reuse existing code whenever possible.
3. Extend existing implementations instead of creating duplicates.
4. Avoid introducing redundant abstractions.

---

## 2. File Header Comments

All newly created files must include a header comment on the first line.

Example:

```dart
// 這個檔案負責使用者資料編輯功能。
// 提供資料更新與頭像上傳功能。
```

---

## 3. Class and Function Documentation

All public classes and functions must include documentation comments in Traditional Chinese.

### Class Example

```dart
/// 編輯使用者資料頁面，允許使用者更新名稱與上傳頭像至 Firebase Storage。
class EditProfilePage { ... }
```

### Function Example

```dart
/// 上傳使用者頭像並回傳下載 URL。
/// 若未選擇圖片則回傳 null。
///
/// Parameters:
/// - id: 使用者 UID
///
/// Returns:
/// - 圖片下載 URL，或 null
Future<String?> uploadAvatar(String id) async { ... }
```

---

## 4. Naming Conventions

* `UpperCamelCase`: classes, widgets
* `lowerCamelCase`: variables, methods
* `kUpperCamelCase` or `lower_snake_case`: constants (follow project consistency)

---

## 5. Code Quality Rules

* Always prefer modifying existing code over creating new files.
* Ensure new features integrate with existing architecture.
* Avoid duplicate services, controllers, or logic layers.
* Keep business logic out of UI widgets.

---

## 6. Formatting

Run the following command before committing:

```bash
dart format .
```

---

## 7. Enforcement (Optional)

If stronger enforcement is needed:

* Add rules to `docs/coding_style.md`
* Implement pre-commit hooks or CI checks

---

## 8. General Rule

Avoid duplicate abstractions under all circumstances.
