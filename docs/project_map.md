# 🗺️ Animora: Карта проекта (Project Map)

Этот документ содержит полную структуру проекта, правила архитектуры и карту файлов, помогающие ИИ-агентам и разработчикам ориентироваться в кодовой базе и поддерживать её целостность.

---

## 📂 Структура каталогов

```
c:\Projects/
├── assets/
│   └── translations/          # Языковые файлы локализации
│       ├── kk.json            # Казахский язык
│       └── ru.json            # Русский язык
│
├── docs/                      # Документация и инструкции для ИИ-агентов
│   ├── agents/                # Системные промты для специализированных ИИ
│   ├── detailed_development_roadmap.md  # План разработки по фазам
│   ├── error_log.md           # Журнал ошибок и их решений
│   ├── n8n_integration_plan.md# План интеграции с n8n
│   ├── project_map.md         # Данный файл (Карта проекта)
│   └── walkthrough.md         # Сценарий первого запуска и тест-драйва
│
├── lib/                       # Исходный код Flutter
│   ├── app.dart               # Настройка MaterialApp.router, тем и локализации
│   ├── main.dart              # Точка входа, инициализация Supabase и EasyLocalization
│   │
│   ├── core/                  # Общие ресурсы и конфигурации
│   │   ├── constants/         # Константы проекта (SupabaseConfig и др.)
│   │   ├── navigation/        # Настройки GoRouter (app_router.dart)
│   │   └── theme/             # Материал 3 дизайн-система (app_theme.dart)
│   │
│   ├── providers/             # Стейт-менеджмент (Riverpod Notifiers)
│   │   ├── auth_provider.dart # Авторизация, сессия Supabase, роли пользователей
│   │   └── data_providers.dart# CRUD-нотификаторы и Future-провайдеры Supabase
│   │
│   └── presentation/          # Графический интерфейс пользователя (UI)
│       ├── auth/              # Авторизация и регистрация
│       │   └── screens/       # login_screen, register_screen, role_selection_screen
│       │
│       ├── owner/             # Интерфейс Владельца питомца (Owner)
│       │   ├── navigation/    # owner_tab_scaffold.dart (вкладки навигации)
│       │   └── screens/       # Экран карты (home), поиск (search), питомцы (pet_list),
│       │                      # карточка клиники и запись (provider_details),
│       │                      # история записей (booking_list), профиль (owner_profile)
│       │
│       └── provider/          # Интерфейс Клиники/Груминга (Provider CRM)
│           ├── navigation/    # provider_tab_scaffold.dart (вкладки навигации)
│           └── screens/       # Дашборд (dashboard), расписание (calendar),
│                              # управление услугами (services), профиль (provider_profile)
│
├── supabase_schema.sql        # Скрипт развертывания таблиц, RLS и триггеров
└── supabase_seed.sql          # Скрипт наполнения базы демонстрационными клиниками
```

---

## 🏗️ Архитектурные правила проекта

Любой агент, вносящий изменения в код, обязан следовать этим правилам:

1.  **Отделение UI от логики (Separation of Concerns):**
    *   Внутри виджетов (`lib/presentation/`) запрещено делать прямые SQL/API запросы к Supabase.
    *   Вся логика работы с базой данных, изменение состояний и кэширование должны находиться в провайдерах (`lib/providers/data_providers.dart` или `lib/providers/auth_provider.dart`).
    *   Виджеты общаются с бэкендом только через чтение состояния (`ref.watch`) или вызов методов нотификатора (`ref.read(provider.notifier).method()`).
2.  **Мультиязычность (Localization):**
    *   Любая строка, отображаемая пользователю, должна быть локализована. Использование хардкодных строк в UI запрещено.
    *   Используйте `tr('key')` из пакета `easy_localization`.
    *   Новые ключи добавляйте синхронно в [ru.json](file:///c:/Projects/assets/translations/ru.json) и [kk.json](file:///c:/Projects/assets/translations/kk.json).
3.  **Совместимость с Riverpod 3.x:**
    *   Не используйте устаревший класс `StateNotifier`. Вместо него применяйте `Notifier` для синхронного состояния и `AsyncNotifier` (или `Notifier<AsyncValue>`) для асинхронных операций.
4.  **Безопасность (Supabase RLS):**
    *   Все новые таблицы в Supabase обязаны иметь включенный RLS (`alter table X enable row level security;`).
    *   Каждое действие пользователя должно быть защищено политикой доступа на уровне базы данных.
5.  **Ведение журнала ошибок:**
    *   При обнаружении и исправлении критических ошибок компиляции/сборки, агент обязан записать описание проблемы и её решение в [docs/error_log.md](file:///c:/Projects/docs/error_log.md).
