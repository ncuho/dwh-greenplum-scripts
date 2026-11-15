import importlib.util
import unittest
from datetime import date
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "orchestration/airflow/batch_parameters.py"
spec = importlib.util.spec_from_file_location("batch_parameters", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BatchParametersTest(unittest.TestCase):
    def test_valid_full_month(self):
        conf = {"batch_id": 1, "run_id": 3, "from_date": "2025-01-01", "to_date": "2025-02-01"}
        self.assertEqual(module.validate_batch(conf), (1, date(2025, 1, 1), date(2025, 2, 1), 3))

    def test_invalid_inputs(self):
        base = {"batch_id": 1, "run_id": 3, "from_date": "2025-01-01", "to_date": "2025-02-01"}
        cases = [
            {**base, "batch_id": 2},
            {**base, "run_id": True},
            {**base, "from_date": "2025-01-02"},
            {**base, "from_date": "20250101"},
            {**base, "to_date": "2027-01-01"},
            {**base, "to_date": "2025-01-01"},
            {**base, "extra": 1},
        ]
        for conf in cases:
            with self.subTest(conf=conf), self.assertRaises(ValueError):
                module.validate_batch(conf)
