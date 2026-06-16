# 🛠️ Animora: Журнал ошибок и решений (Error Log)

Этот журнал предназначен для ИИ-агентов и разработчиков. Записывайте сюда все критические ошибки сборки, компиляции или выполнения, а также способы их решения, чтобы не наступать на те же грабли в будущем.

---

## 1. Конфликт версий Riverpod и StateNotifier
*   **Дата:** 16 июня 2026
*   **Симптом:**
    При запуске статического анализа (`flutter analyze`) возникали ошибки вида:
    `Classes can only extend other classes - extends_non_class` для `StateNotifier` и `The function 'StateNotifierProvider' isn't defined`.
*   **Причина:**
    В проекте установлена версия Flutter 3.41+ и соответствующий Dart SDK. В новых версиях Riverpod (v3.0+) класс `StateNotifier` и `StateNotifierProvider` были полностью удалены в пользу современных `Notifier` и `NotifierProvider`.
*   **Решение:**
    Все провайдеры переписаны с использованием нового класса `Notifier<T>` и генерацией начального состояния через переопределение метода `build()`.
    *Пример правильной реализации:*
    ```dart
    class AuthNotifier extends Notifier<AuthState> {
      @override
      AuthState build() {
        _init();
        return AuthState();
      }
      // ... методы изменения состояния
    }

    final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
      return AuthNotifier();
    });
    ```

---

## 2. Ошибка типов CardTheme в ThemeData
*   **Дата:** 16 июня 2026
*   **Симптом:**
    Ошибка компиляции: `The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'.` в `app_theme.dart`.
*   **Причина:**
    В Flutter свойство `ThemeData.cardTheme` принимает тип `CardThemeData`, а не сам виджет `CardTheme`.
*   **Решение:**
    В файле [app_theme.dart](file:///c:/Projects/lib/core/theme/app_theme.dart) заменена инициализация:
    `cardTheme: CardTheme(...)` -> `cardTheme: CardThemeData(...)`.

---

## 3. Ошибка параметров в NavigationDestination
*   **Дата:** 16 июня 2026
*   **Симптом:**
    Ошибка компиляции: `The named parameter 'activeIcon' isn't defined` в `NavigationBar` таб-панелей.
*   **Причина:**
    В виджете `NavigationDestination` для выделенной иконки используется параметр `selectedIcon`, а не `activeIcon` (который используется в старом `BottomNavigationBar`).
*   **Решение:**
    В файлах навигации [owner_tab_scaffold.dart](file:///c:/Projects/lib/presentation/owner/navigation/owner_tab_scaffold.dart) и [provider_tab_scaffold.dart](file:///c:/Projects/lib/presentation/provider/navigation/provider_tab_scaffold.dart) параметр `activeIcon` заменен на `selectedIcon`.

---

## 4. Несуществующие иконки в стандартном пакете
*   **Дата:** 16 июня 2026
*   **Симптом:**
    Ошибки компиляции: `The getter 'dog_house_rounded' isn't defined for the type 'Icons'` и `The getter 'cat' isn't defined`.
*   **Причина:**
    В стандартном пакете Material Icons нет отдельных векторных иконок для кошек и собачьих будок.
*   **Решение:**
    В файле [pet_list_screen.dart](file:///c:/Projects/lib/presentation/owner/screens/pet_list_screen.dart) иконки заменены на стандартную и доступную `Icons.pets_rounded`.

---

## 5. Ошибки позиционирования Row
*   **Дата:** 16 июня 2026
*   **Симптом:**
    `There's no constant named 'between' in 'MainAxisAlignment'`
*   **Причина:**
    Опечатка в коде. Константы `MainAxisAlignment.between` не существует.
*   **Решение:**
    Заменено на корректное `MainAxisAlignment.spaceBetween`.
