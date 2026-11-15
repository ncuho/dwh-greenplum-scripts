import importlib.util,json,math,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('loader',ROOT/'scripts/load_mirrors.py');loader=importlib.util.module_from_spec(spec);spec.loader.exec_module(loader)
class ContractTest(unittest.TestCase):
 def test_manifest(self):
  m=json.loads((ROOT/'metadata/asset-manifest.json').read_text());names=[a['name'] for a in m['assets']];self.assertEqual(len(names),85);self.assertEqual(len(set(names)),85);self.assertEqual(sum(a['class']=='exact_existing_mirror' for a in m['assets']),46)
  for r in m['relations']:
   self.assertIn(r['source'],names);self.assertIn(r['target'],names)
 def test_copy_escaping(self):
  self.assertEqual(loader.copy_cell(None),r'\N');self.assertEqual(loader.copy_cell(r'\N'),r'\\N');self.assertEqual(loader.copy_cell('a\tb\nc\r'),r'a\tb\nc\r');self.assertEqual(loader.copy_cell(True),'t')
 def test_double_roundtrip(self):
  for n in [0.1,1.0000000000000002,math.nextafter(64.0,0.0),-1e-300]:self.assertEqual(float(loader.copy_cell(n)).hex(),n.hex())
  with self.assertRaises(ValueError):loader.copy_cell(float('nan'))
if __name__=='__main__':unittest.main()
