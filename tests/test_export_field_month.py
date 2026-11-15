import contextlib
import importlib.util
import io
import sys
import types
import unittest
from datetime import date
from pathlib import Path
from unittest import mock

path = Path(__file__).resolve().parents[1] / "jobs/export_field_month.py"
spec = importlib.util.spec_from_file_location("export_field_month", path)
job = importlib.util.module_from_spec(spec)
spec.loader.exec_module(job)


class Cursor:
    description = [("locality_id",), ("month_start",)]

    def __init__(self):
        self.query = None
        self.calls = 0

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False

    def execute(self, query, params):
        self.query = (query, params)

    def fetchmany(self, size):
        self.calls += 1
        return [(4, date(2025, 1, 1))] if self.calls == 1 else []


class Connection:
    def __init__(self):
        self.current = Cursor()
        self.session = None
        self.rolled_back = False
        self.closed = False

    def set_session(self, **kwargs):
        self.session = kwargs

    def cursor(self):
        return self.current

    def rollback(self):
        self.rolled_back = True

    def close(self):
        self.closed = True


class ExportJobTests(unittest.TestCase):
    def test_csv_and_read_only_query(self):
        connection = Connection()
        fake_driver = types.SimpleNamespace(connect=lambda _: connection)
        output = io.StringIO()
        with mock.patch.dict(sys.modules, {"psycopg2": fake_driver}), contextlib.redirect_stdout(output):
            job.main(["--from-month", "2025-01-01", "--to-month", "2025-02-01"])
        self.assertTrue(connection.session["readonly"])
        self.assertTrue(connection.rolled_back and connection.closed)
        self.assertEqual(connection.current.query[1], (date(2025, 1, 1), date(2025, 2, 1)))
        self.assertEqual(output.getvalue().splitlines(), ["locality_id,month_start", "4,2025-01-01"])

    def test_reject_non_month_and_invalid_range(self):
        for args in (["2025-01-02", "2025-02-01"], ["2025-02-01", "2025-01-01"]):
            with self.subTest(args=args), contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                job.main(["--from-month", args[0], "--to-month", args[1]])


if __name__ == "__main__":
    unittest.main()
