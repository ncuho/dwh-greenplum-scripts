"""Verify the selected source files are present and unchanged."""
import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SourceFilesTest(unittest.TestCase):
    def test_selected_sources_unchanged(self):
        manifest = json.loads((ROOT / "tests/source_hashes.json").read_text())
        actual = {str(p.relative_to(ROOT)) for p in ROOT.rglob("*.sql") if ".git" not in p.parts}
        self.assertEqual(actual, set(manifest))
        for name, expected in manifest.items():
            with self.subTest(file=name):
                self.assertEqual(hashlib.sha256((ROOT / name).read_bytes()).hexdigest(), expected)

    def test_production_dependencies_present(self):
        required = [
            "ddl/tables/ods/og_tbl_production_volume.sql",
            "ddl/tables/ods/og_tbl_well.sql",
            "ddl/tables/ref/calendar.sql",
            "ddl/tables/dds/dim_well_scd2.sql",
            "ddl/tables/dds/fact_downtime_interval.sql",
            "ddl/tables/dds/fact_production_day.sql",
            "functions/etl/rebuild_production_day.sql",
        ]
        for name in required:
            with self.subTest(file=name):
                self.assertTrue((ROOT / name).is_file())
