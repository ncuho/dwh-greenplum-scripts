"""Characterization tests: formatting and file extraction preserve SQL tokens and include order."""
import json,re,unittest
from pathlib import Path
from sql_tokens import digest
ROOT=Path(__file__).resolve().parents[1]
class SqlLayoutTests(unittest.TestCase):
 def test_all_extracted_statements_keep_tokens(self):
  fixture=json.loads((ROOT/'tests/fixtures/sql-contract.json').read_text())
  self.assertEqual(len(fixture['files']),288)
  for entry in fixture['files']:
   with self.subTest(file=entry['file']):self.assertEqual(digest((ROOT/entry['file']).read_text()),entry['token_sha256'])
 def test_bootstrap_statement_and_include_order(self):
  fixture=json.loads((ROOT/'tests/fixtures/sql-contract.json').read_text())
  for file,expected in fixture['wrappers'].items():self.assertEqual((ROOT/file).read_text(),expected)
 def test_include_paths_exist_and_stay_inside_repository(self):
  for p in ROOT.rglob('*.sql'):
   for line in p.read_text().splitlines():
    if line.startswith('\\ir '):
     target=(p.parent/line[4:].strip()).resolve();self.assertIn(ROOT,target.parents);self.assertTrue(target.is_file(),str(target))
 def test_object_inventory(self):
  self.assertEqual(len(list((ROOT/'ddl/tables').rglob('*.sql'))),85)
  self.assertEqual(len(list((ROOT/'functions/etl').glob('*.sql'))),8)
  self.assertEqual(len(list((ROOT/'ddl/views').rglob('*.sql'))),2)
  self.assertEqual(len(list((ROOT/'ddl/materialized_views').rglob('*.sql'))),1)
 def test_only_greenplum_source_scope(self):
  self.assertFalse((ROOT/'migration').exists());self.assertFalse((ROOT/'scripts').exists())
  for p in (ROOT/'dql').rglob('*.sql'):
   self.assertTrue(p.read_text().lstrip().upper().startswith('SELECT'))
 def test_technical_identifiers_are_neutral(self):
  for p in ROOT.rglob('*.sql'):
   # Keep original data literals intact; only code identifiers are in rename scope.
   sql=re.sub(r"'(?:''|[^'])*'", "''",p.read_text())
   self.assertIsNone(re.search(r'\bsng_',sql,re.I),str(p))
if __name__=='__main__':unittest.main()
