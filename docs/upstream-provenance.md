# Происхождение Greenplum

Источник: официальный архив `greenplum-db/gpdb-archive`, commit `609ff2bb9ccb7d393d772b29770e757dbd2ecc79` (6.26.2), локально собран на Ubuntu 22.04 amd64. GPORCA включён; GP-patched Xerces: `greenplum-db/gp-xerces-archive`, commit `d34648b172a3741072d5b1d4a490f80cac82c475`. Закреплённые официальные URL и контрольные суммы исходных архивов — в `metadata/upstream-source-lock.json`.

Исходники не патчились. VERSION metadata добавлена для сохранения версии/commit в архивной сборке без git tags. Исторический tag неподписанный; официальный commit подтверждён. Это upstream source build, не community/Yandex fork и не сертифицированный предсобранный binary Broadcom. Репозиторий содержит прикладную SQL-модель и не распространяет бинарник GP.

Конфигурация: coordinator + 2 primary segments, без standby и segment mirrors. HA, промышленная отказоустойчивость и сертифицированная производительность не заявлены. Resource manager queue.
