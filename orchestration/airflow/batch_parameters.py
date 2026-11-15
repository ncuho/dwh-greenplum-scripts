"""Input contract for a manually submitted production calculation batch."""
from datetime import date


def validate_batch(conf):
    if not isinstance(conf, dict):
        raise ValueError("A configuration object is required")
    required = {"batch_id", "run_id", "from_date", "to_date"}
    if set(conf) != required:
        raise ValueError("Provide exactly batch_id, run_id, from_date and to_date")
    for name in ("batch_id", "run_id"):
        if type(conf[name]) is not int or conf[name] <= 0:
            raise ValueError(f"{name} must be a positive integer")
    if conf["batch_id"] != 1:
        raise ValueError("Existing calculation accepts batch_id 1 only")
    try:
        start = date.fromisoformat(conf["from_date"])
        end = date.fromisoformat(conf["to_date"])
    except (TypeError, ValueError) as exc:
        raise ValueError("Dates must use YYYY-MM-DD") from exc
    if start.isoformat() != conf["from_date"] or end.isoformat() != conf["to_date"]:
        raise ValueError("Dates must use YYYY-MM-DD")
    if start.day != 1 or end.day != 1 or not (date(2025, 1, 1) <= start < end <= date(2026, 1, 1)):
        raise ValueError("Use a nonempty complete-month interval within 2025; end is exclusive")
    return conf["batch_id"], start, end, conf["run_id"]
