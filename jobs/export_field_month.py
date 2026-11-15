"""Read field/month summaries through libpq service and write CSV to stdout.

Requires psycopg2 and an already configured libpq service. No code is executed
unless called as a program. The source relation is the existing GP mart.
"""
import argparse
import csv
import sys
from datetime import date

SQL = """
SELECT locality_id, month_start, oil_actual_legacy, oil_plan_legacy,
       plan_attainment_pct, energy_cost_rub, downtime_hours, run_id
FROM dm.field_month_performance
WHERE month_start >= %s AND month_start < %s
ORDER BY month_start, locality_id
"""


def parse_month(value):
    parsed = date.fromisoformat(value)
    if parsed.isoformat() != value or parsed.day != 1:
        raise argparse.ArgumentTypeError("Expected the first of a month as YYYY-MM-DD")
    return parsed


def main(argv=None):
    parser = argparse.ArgumentParser(description="Export field/month rows as CSV")
    parser.add_argument("--from-month", type=parse_month, required=True)
    parser.add_argument("--to-month", type=parse_month, required=True, help="exclusive")
    args = parser.parse_args(argv)
    if args.from_month >= args.to_month:
        parser.error("--to-month must be later than --from-month")

    import psycopg2  # Optional dependency on the host that executes this job.

    connection = psycopg2.connect("")  # libpq environment or service; no embedded secrets.
    try:
        connection.set_session(readonly=True, autocommit=False)
        with connection.cursor() as cursor:
            cursor.execute(SQL, (args.from_month, args.to_month))
            writer = csv.writer(sys.stdout)
            writer.writerow([column[0] for column in cursor.description])
            while True:
                rows = cursor.fetchmany(1000)
                if not rows:
                    break
                writer.writerows(rows)
        connection.rollback()
    finally:
        connection.close()


if __name__ == "__main__":
    main()
