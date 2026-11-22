# coalesce_ready_batches

Объединяет ограниченный диапазон READY-партий одного источника с сохранением происхождения. Работает под общей блокировкой writer.

Тип: хранимая функция PL/pgSQL Greenplum 6; это не процедура CALL.

Исходный код: [coalesce_ready_batches.sql](coalesce_ready_batches.sql).
