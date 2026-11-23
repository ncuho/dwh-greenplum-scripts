"""Register factual data transformations and source-release validation inputs."""
import json
import os
from urllib.parse import quote
from urllib.request import Request, urlopen


PREFIX = "og_greenplum.og_dwh."
INPUTS = {
    "oil_stg.batch_control": "prepare_source выбирает READY-партии; apply_batch проверяет статус и фиксирует APPLIED.",
    "oil_stg.kafka_checkpoint": "prepare_source блокирует checkpoint и читает next_offset по партициям для согласованной границы.",
    "oil_stg.batch_coalesce_map": "prepare_source проверяет, что каждая объединённая партия применена; validate_coalesce_audit сверяет происхождение доставок.",
    "oil_stg.batch_coalesce_event_map": "Python validate_coalesce_audit в release() читает карту доставок после prepare_source и до commit; нарушение откатывает весь запуск.",
    "oil_dds.hub_field": "apply_batch читает hub_field для исключения повторных ключей и проверки коллизий; нарушение откатывает общую транзакцию.",
    "oil_dds.hub_well": "apply_batch читает hub_well для исключения повторных ключей и проверки коллизий; нарушение откатывает общую транзакцию.",
    "oil_dds.hub_production_day": "apply_batch читает hub_production_day для исключения повторных ключей и проверки коллизий; нарушение откатывает общую транзакцию.",
}


# Сохраняем уже существующие колоночные связи; новые служебные связи описывают входы проверок, а не происхождение oil_tonnes.
def register(call):
    """Add only verified relationships and increase the initial canvas depth."""
    pipeline = call("pipelines/name/webinar_airflow.oil_gp_release?fields=tasks")
    cache = {}
    before = []
    applied = []

    def table(name):
        """Читает карточку исходной таблицы и повторно использует её в рамках регистрации."""
        if name not in cache:
            cache[name] = call("tables/name/" + quote(PREFIX + name, safe=""))
        return cache[name]

    def edge(source, target, description, columns=None):
        """Добавляет подтверждённую связь, сохраняя существующее происхождение колонок."""
        source_type = "pipeline" if source["id"] == pipeline["id"] else "table"
        target_type = "pipeline" if target["id"] == pipeline["id"] else "table"
        graph = call("lineage/" + target_type + "/" + target["id"] + "?upstreamDepth=1&downstreamDepth=0")
        old = next((e for e in graph.get("upstreamEdges", []) if e["fromEntity"] == source["id"] and e["toEntity"] == target["id"]), None)
        before.append({"from": source["id"], "fromType": source_type, "to": target["id"], "toType": target_type, "previous": old})
        details = {k: v for k, v in (old or {}).get("lineageDetails", {}).items() if k in {"sqlQuery", "columnsLineage", "pipeline", "description", "source"}}
        details["description"] = description
        details["source"] = "Manual"
        if columns is not None:
            existing = details.get("columnsLineage", [])
            for mapping in columns:
                if not any(x.get("toColumn") == mapping["toColumn"] and x.get("fromColumns") == mapping["fromColumns"] for x in existing):
                    existing.append(mapping)
            details["columnsLineage"] = existing
        call("lineage", "PUT", {"edge": {"fromEntity": {"id": source["id"], "type": source_type}, "toEntity": {"id": target["id"], "type": target_type}, "lineageDetails": details}})
        applied.append({"from": source["fullyQualifiedName"], "to": target["fullyQualifiedName"]})

    for name, reason in INPUTS.items():
        edge(table(name), pipeline, "Операционный вход source release. " + reason + " Это зависимость обработки/контроля качества, без переноса значений колонок в отчёт.")

    # Функция действительно строит эти hubs из event.entity_id; hash считается с соответствующим префиксом.
    events = table("oil_dds.event")
    for name, business, hash_key, prefix in [
        ("hub_field", "field_id", "field_hk", "field:"),
        ("hub_well", "well_id", "well_hk", "well:"),
        ("hub_production_day", "production_id", "production_hk", "production:"),
    ]:
        target = table("oil_dds." + name)
        pairs = [("entity_id", business), ("entity_id", hash_key), ("load_dts", "load_dts"), ("record_source", "record_source")]
        columns = [{"fromColumns": [events["fullyQualifiedName"] + "." + a], "toColumn": target["fullyQualifiedName"] + "." + b} for a, b in pairs]
        edge(events, target, "apply_batch: INSERT из event с фильтром event_type, исключением существующего бизнес-ключа и GROUP BY entity_id. " + hash_key + " = md5('" + prefix + "' || entity_id); load_dts и record_source берутся через min().", columns)

    # Это реальные выходы refresh_production, вызываемой исходным DAG; view отчёта продолжает читать agg_field_day.
    for name in ["dim_field", "dim_well", "fact_well_day", "agg_field_day"]:
        edge(pipeline, table("oil_mart." + name), "Source DAG вызывает bridge_capture.prepare_source; при READY выполняется oil_mart.refresh_production, которая пересчитывает этот объект в общей GP-транзакции. Код в GitHub и Airflow Code; отдельная Spark-обработка здесь не выполняется.")

    settings = call("system/settings/lineageSettings")
    previous_settings = json.loads(json.dumps(settings))
    value = settings["config_value"]
    value["upstreamDepth"] = 12
    value["downstreamDepth"] = max(value.get("downstreamDepth", 0), 2)
    value["pipelineViewMode"] = "Node"
    call("system/settings", "PUT", {"config_type": "lineageSettings", "config_value": value})
    return {"edges": applied, "previous_edges": before, "previous_settings": previous_settings, "upstream_depth": 12}


# Токен берётся только из окружения; в Git и отчёт регистрации он не записывается.
def main():
    host = os.environ["OPENMETADATA_HOST"].rstrip("/")
    token = os.environ["OPENMETADATA_JWT_TOKEN"]

    def call(path, method="GET", body=None):
        """Отправляет запрос каталогу с токеном из окружения и читает JSON-ответ."""
        request = Request(host + "/api/v1/" + path, data=json.dumps(body).encode() if body is not None else None, headers={"Content-Type": "application/json", "Authorization": "Bearer " + token}, method=method)
        with urlopen(request, timeout=30) as response:
            data = response.read()
            return json.loads(data) if data else {}

    result = register(call)
    print(json.dumps({"edges": result["edges"], "upstream_depth": result["upstream_depth"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
