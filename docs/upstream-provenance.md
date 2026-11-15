# Происхождение Greenplum

Источник: официальный архив `greenplum-db/gpdb-archive`, commit `609 ff2 bb9 ccb7 d393 d772 b29770 e757 dbd2 ecc79` (6.26.2), локально собран на Ubuntu 22.04 amd64. GPORCA включён; GP-patched Xerces: `greenplum-db/gp-xerces-archive`, commit `d34648 b172 a3741072 d5 b1 d4 a490 f80 cac82 c475`. Закреплённые официальные URL и контрольные суммы исходных архивов — в `metadata/upstream-source-lock.json`.

Исходники не патчились. VERSION metadata добавлена для сохранения версии/commit в архивной сборке без git tags. Исторический tag неподписанный; официальный commit подтверждён. Это upstream source build, не community/Yandex fork и не сертифицированный предсобранный binary Broadcom. Репозиторий содержит прикладную SQL-модель и не распространяет бинарник GP.

Конфигурация: coordinator + 2 primary segments, без standby и segment mirrors. HA, промышленная отказоустойчивость и сертифицированная производительность не заявлены. Resource manager queue.
