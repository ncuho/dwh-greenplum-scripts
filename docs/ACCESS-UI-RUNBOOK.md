# Перенос доступов: CIAM и LakeKeeper

Настройки проверены 22 ноября 2026. Правила берутся из HOWTO-26.2.1-017 и HOWTO-26.2.1-018; на стенде CIAM Flow сообщает `v26.1.0`. Номер всей платформы не выводится из номера отдельного компонента.

## Что уже настроено

В CIAM созданы `oil_dlh_reader` и `oil_dlh_engineer`. Их коды связаны с `source-id` одноимённых ролей LakeKeeper. Права добавлены через штатный LakeKeeper Management API, используемый интерфейсом `Permissions`; существующие назначения не удалялись.

| Исходная задача в GP | Целевая роль CIAM | Область и права LakeKeeper |
|---|---|---|
| Чтение опубликованных витрин и отчётность | `oil_dlh_reader` | `describe` warehouse; `describe/select` только `oil_mart` |
| Обработка staging, DDS и marts | `oil_dlh_engineer` | `describe` warehouse; `describe/select/create/modify` в трёх `oil_*` namespaces |
| Kafka sink | Отдельный CIAM service client | Изолированное право `modify` только на `oil_stg.event_log_wave2`; не роль пользователя отчёта |

Это перенос назначения прав, а не буквальное копирование GP GRANT в Iceberg. GP SECURITY DEFINER-функции и PostgreSQL роли не становятся ролями LakeKeeper автоматически. `modify` в установленной модели включает дополнительные действия, в том числе rename/drop; это видимая семантика штатной роли, а не произвольный write-only грант.

Фактические readback и положительные/отрицательные проверки роли находятся в `lakekeeper-role-evidence.json`, `role-effective-access.json` и `role-table-access.json`. Для reader чтение `oil_mart.agg_field_day` разрешено, запись запрещена; чтение staging и DDS запрещено. Для engineer чтение и запись разрешены в указанных слоях. Это проверки effective access роли; они не заменяют вход конкретного человека с ролью.

## Что показывать в интерфейсах

1. Откройте `https://dp-103.mcs.local/iam-admin/`, выберите tenant платформы и раздел **Роли**. Найдите два кода `oil_dlh_reader` и `oil_dlh_engineer`; они уже созданы, повторно создавать их не требуется.
2. В карточке предназначенного для демонстрации пользователя добавьте роль reader. Для показа запрета выбирайте пользователя без `tenant_admin`: администратор перекрывает ограничительные примеры своими дополнительными правами. Не снимайте рабочие роли с реальных пользователей ради демонстрации.
3. Согласно инструкции 26.2.1, один раз войдите этим пользователем в UI LakeKeeper или через штатное SSO-подключение Trino/Cedrus. LakeKeeper узнаёт пользователя и его роли при аутентификации; затем администратор видит их в **Roles**.
4. Откройте LakeKeeper UI `https://10.0.2.13/`, **Warehouses → dlh → oil_mart → Permissions**. Через **Grant → Roles** найдите `oil_dlh_reader`; покажите уже назначенные `describe/select`. Новые права для демонстрации добавлять не требуется.
5. Откройте `oil_stg` и `oil_dds`, затем вкладки **Permissions**: reader не имеет доступа к данным этих слоёв. Роль engineer имеет `describe/select/create/modify` в каждом из трёх слоёв. Метаданные отдельных ресурсов могут быть видны через warehouse describe, что не даёт чтения строк.
6. Для нового immutable release выдавайте reader доступ только к двум опубликованным serving-таблицам. В release namespace могут находиться canonical events и DDS, поэтому namespace-wide SELECT для reader здесь не подходит. Для этого подготовлен `target/grant_serving.py`.
7. Отдельно откройте Superset. Доступ к панели и SQL Lab регулируется RBAC Superset; соединение BI с Cedrus использует сервисную identity. Выдача роли LakeKeeper сама по себе не выдаёт доступ к dashboard и не превращает сервисное соединение Superset в per-user impersonation.

## Совместимость представлений и TLS

Установленная политика Cedrus запрашивала для Iceberg view действие `select`, которого нет в API установленного LakeKeeper (HTTP 422). Для панели используется физическая `dlh.oil_mart.agg_field_day`. Невостребованный целевой view выведен из эксплуатации и каталога; его metadata сохранена локально в закрытом файле. Проверки доступа не отключались и политики OPA не ослаблялись.

Для Superset MCP включена проверка сертификата по публичному корневому CA платформы; он больше не работает с `SUPERSET_VERIFY=false`. Встроенный браузер не доверяет этому CA при SSO-переходе к CIAM. Предупреждение не обходилось: для визуальной проверки полного SSO нужен браузер, в котором штатно установлен доверенный корневой сертификат стенда. API и локальная панель ingestion проверены отдельно.

## Документы

- [HOWTO-26.2.1-017: роли CIAM и права LakeKeeper](https://confluence.vk.team/pages/viewpage.action?pageId=2305692569)
- [HOWTO-26.2.1-018: Trino → LakeKeeper → S3](https://confluence.vk.team/pages/viewpage.action?pageId=2305146651)
- [Соответствие ролей LakeKeeper и CIAM](https://confluence.vk.team/pages/viewpage.action?pageId=2107114753)
- [Интеграция и назначение ролей Trino + LakeKeeper](https://confluence.vk.team/pages/viewpage.action?pageId=2234048919)

RFC-013 описывает другой интерфейс управления доступами с планом внедрения 26.3; его конфигурации Cedar не применялись как инструкция для установленного OpenFGA-контура.
