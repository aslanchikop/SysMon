# 📝 Animora: Журнал разработки и Карта проекта (Developer Log & AI Guide)

Этот документ создан для координации разработчиков и ИИ-ассистентов. Он содержит актуальную карту проекта, журнал решенных технических проблем (ошибок) и правила для ИИ, чтобы предотвратить потерю контекста при долгосрочной работе.

---

## 🗺️ 1. Карта проекта (Project Map)

Для быстрого ориентирования в кодовой базе используйте эту структуру:

*   [supabase_schema.sql](file:///c:/Projects/supabase_schema.sql) — Схема базы данных PostgreSQL (RLS, триггеры, внешние ключи).
*   [supabase_seed.sql](file:///c:/Projects/supabase_seed.sql) — Демонстрационные данные клиник и услуг Астаны для тестирования.
*   `lib/` — Основной код приложения:
    *   `main.dart` — Инициализация Supabase, локализации и точка запуска.
    *   `app.dart` — Настройка тем, локалей и GoRouter.
    *   `core/`
        *   `constants/supabase_config.dart` — URL и ключи бэкенда.
        *   `navigation/app_router.dart` — Маршруты с проверкой ролей (Owner/Provider).
        *   `theme/app_theme.dart` — Стилизация Material 3 (светлая/темная темы).
    *   `providers/`
        *   [auth_provider.dart](file:///c:/Projects/lib/providers/auth_provider.dart) — Состояние входа и ролевая модель пользователя.
        *   [data_providers.dart](file:///c:/Projects/lib/providers/data_providers.dart) — CRUD-провайдеры (выборка клиник, управление записями и питомцами).
    *   `presentation/` — Интерфейс (UI):
        *   `auth/` — Авторизация, регистрация и выбор роли.
        *   `owner/` — Экраны владельца питомца (Карта, Детали клиники + Букинг, Питомцы, Записи, Профиль).
        *   `provider/` — Кабинет клиники/груминга (Дашборд с заявками, Календарь, Редактор услуг, Профиль бизнеса).
*   `assets/translations/` — Языковые пакеты [ru.json](file:///c:/Projects/assets/translations/ru.json) и [kk.json](file:///c:/Projects/assets/translations/kk.json).
*   `docs/` — Документация, инструкции по n8n и дорожная карта.

---

## 🛡️ 2. Правила для ИИ-ассистента (AI Guidelines)

Если вы — ИИ-ассистент, продолжающий работу над проектом Animora, строго следуйте этим инструкциям:

1.  **Не ломайте Riverpod:** В проекте используется Riverpod v3+. Legacy-классы типа `StateNotifier` и `StateNotifierProvider` **удалены**. Используйте только современные `Notifier` / `AsyncNotifier` и `NotifierProvider`.
2.  **Синхронизация с БД:** При любом изменении полей в Dart-моделях или провайдерах (например, в таблице `pets` или `bookings`), обязательно синхронизируйте эти изменения с SQL-файлами `supabase_schema.sql` и `supabase_seed.sql`.
3.  **Локализация:** Все новые тексты, кнопки, ошибки и диалоги в UI пишите через вызов `tr('key')` и добавляйте переводы в оба файла локализации (`ru.json` и `kk.json`). Никакого хардкода строк в виджетах.
4.  **Ведение журнала:** При столкновении с любой новой ошибкой компиляции или выполнения, после её решения добавьте запись в таблицу ниже (раздел 3).

---

## 📓 3. Журнал Ошибок и Решений (Error & Solution Log)

| Дата | Ошибка (Что сломалось) | Причина возникновения | Решение (Как починили) |
| :--- | :--- | :--- | :--- |
| **16.06.2026** | `extends_non_class` для `StateNotifier` и `undefined_function` для `StateNotifierProvider` | В проекте установлена новая версия Riverpod 3.0+, где устаревшие провайдеры были полностью удалены из SDK. | Все провайдеры (`AuthNotifier`, `BookingNotifier`, `PetNotifier`) переписаны на современный стандарт `Notifier` / `NotifierProvider`. |
| **16.06.2026** | `There's no constant named 'between' in 'MainAxisAlignment'` | Опечатка в коде выравнивания элементов Row в экранах деталей клиники и записей. | Заменено на `MainAxisAlignment.spaceBetween` во всех виджетах. |
| **16.06.2026** | `The named parameter 'activeIcon' isn't defined` в `NavigationBar` | Параметр `activeIcon` не поддерживается в `NavigationDestination` (он используется в старом `BottomNavigationBar`). | Заменен на корректный параметр `selectedIcon` в `owner_tab_scaffold` и `provider_tab_scaffold`. |
| **16.06.2026** | `The getter 'dog_house_rounded' / 'cat' isn't defined for the type 'Icons'` | Попытка использовать несуществующие иконки животных из стандартного Material-пакета. | Заменено на универсальную и существующую иконку `Icons.pets_rounded` для кошек и собак. |
| **16.06.2026** | `The argument type 'CardTheme' can't be assigned to...` | Несовместимость типов данных в `ThemeData` при настройке стиля карточек. | Тип данных изменен с `CardTheme` на `CardThemeData`. |
