# 🧠 Animora: Состояние проекта и Навигатор контекста (Project State & Debug Journal)

> [!IMPORTANT]
> **ИНСТРУКЦИЯ ДЛЯ ИИ-АГЕНТОВ (SYSTEM INSTRUCTION):**
> 1. Всегда читайте этот файл перед началом работы, чтобы понять текущую архитектуру и историю ошибок.
> 2. После внесения изменений в код или структуру файлов вы **ОБЯЗАНЫ** обновить карту проекта в этом файле.
> 3. При возникновении и успешном решении любой ошибки/бага внесите его в раздел **«Журнал отладки (Debug Journal)»** внизу этого файла, указав симптом, причину и решение.

---

## 🗺️ Карта архитектуры проекта (Project Map)

```
c:\Projects/
├── assets/
│   └── translations/           # Файлы мультиязычности (easy_localization)
│       ├── ru.json             # Русский языковой пакет
│       └── kk.json             # Казахский языковой пакет
│
├── docs/                       # Документация проекта (сохранение контекста)
│   ├── detailed_development_roadmap.md # Дорожная карта по этапам
│   ├── n8n_integration_plan.md  # План автоматизации и уведомлений n8n
│   ├── task.md                 # Живой TODO-лист проекта
│   └── project_state.md        # [ЭТОТ ФАЙЛ] Состояние проекта, ошибки и карта
│
├── lib/                        # Исходный код Flutter (Dart)
│   ├── main.dart               # Инициализация (Supabase, Локализация) и точка входа
│   ├── app.dart                # Корневой виджет (темы, роутер, локаль)
│   │
│   ├── core/                   # Системное ядро приложения
│   │   ├── constants/
│   │   │   └── supabase_config.dart # Ключи подключения к Supabase
│   │   ├── navigation/
│   │   │   └── app_router.dart # Настройка GoRouter (ролевая модель)
│   │   └── theme/
│   │       └── app_theme.dart  # Дизайн-система Material 3 (светлая/темная)
│   │
│   ├── providers/              # Управление состоянием (Riverpod Notifiers)
│   │   ├── auth_provider.dart  # Авторизация, сессия Supabase, профили пользователей
│   │   └── data_providers.dart # Запросы к бэкенду (списки клиник, питомцы, записи)
│   │
│   └── presentation/           # Интерфейс пользователя (UI Экраны)
│       ├── auth/               # Экраны входа, регистрации и выбора роли
│       │
│       ├── owner/              # Интерфейс Владельца питомца (Owner)
│       │   ├── navigation/     # Нижний NavigationBar владельца
│       │   └── screens/        # Экраны (Home-карта, Поиск, Питомцы, Записи, Профиль)
│       │
│       └── provider/           # Интерфейс Клиники/Груминга (Provider CRM)
│           ├── navigation/     # Нижний NavigationBar провайдера
│           └── screens/        # Экраны (Дашборд, Календарь, Услуги, Профиль)
│
├── supabase_schema.sql         # SQL-скрипт создания таблиц, триггеров и RLS в Supabase
├── supabase_seed.sql           # SQL-скрипт наполнения базы клиниками Астаны
└── test/
    └── supabase_connection_test.dart # Скрипт проверки подключения к бэкенду
```

---

## 🐞 Журнал отладки (Debug Journal)

В этой таблице фиксируются все критические ошибки, возникшие в ходе разработки, их причины и способы решения, чтобы избежать повторения.

| Дата | Файл / Модуль | Ошибка / Симптом | Причина | Решение |
| :--- | :--- | :--- | :--- | :--- |
| 16.06.26 | `auth_provider.dart` `data_providers.dart` | `extends_non_class - StateNotifier` & `undefined_function` | В Riverpod 3.0+ классы `StateNotifier` и `StateNotifierProvider` были удалены. | Все нотификаторы переписаны на современный стандарт `Notifier` и `NotifierProvider` с переопределением метода `build()`. |
| 16.06.26 | `dashboard_screen.dart` `provider_details_screen.dart` | `undefined_enum_constant - between` | Опечатка: обращение к константе `MainAxisAlignment.between`. | Заменено на корректное `MainAxisAlignment.spaceBetween`. |
| 16.06.26 | `dashboard_screen.dart` | `undefined_named_parameter - border` | У `RoundedRectangleBorder` нет параметра `border`. | Заменено на `side: BorderSide(...)`. |
| 16.06.26 | `owner_tab_scaffold.dart` `provider_tab_scaffold.dart` | `undefined_named_parameter - activeIcon` | У `NavigationDestination` нет параметра `activeIcon`. | Заменено на корректное `selectedIcon`. |
| 16.06.26 | `pet_list_screen.dart` | `undefined_getter - dog_house_rounded` & `cat` | Иконки `Icons.dog_house_rounded` и `cat` отсутствуют в базовом шрифте Material. | Заменены на универсальную иконку `Icons.pets_rounded` для обеих категорий. |
| 16.06.26 | `services_screen.dart` | `undefined_identifier - authProvider` | Отсутствовал явный импорт `auth_provider.dart` в файле. | Добавлен `import '../../../providers/auth_provider.dart';`. |
| 16.06.26 | `widget_test.dart` | Ошибка компиляции тестов из-за отсутствия класса `MyApp`. | Базовый тест Flutter-шаблона ссылался на удаленный класс `MyApp`. | Тест переписан в простой независимый юнит-тест `Simple smoke test`. |

---

## 🎯 Текущий фокус разработки

1. **Развертывание Supabase и первый запуск приложения:** Выполнение ЭТАПА 1 из дорожной карты.
2. **Локальный n8n:** Создание туннеля вебхуков для отправки сообщений о записях в Telegram.
