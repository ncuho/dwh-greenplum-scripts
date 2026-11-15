#!/usr/bin/env python3
"""Import authorized private snapshots using libpq service configuration."""
import argparse, decimal, json, os, re, subprocess, tempfile
from pathlib import Path

def copy_cell(v):
    if v is None: return r'\N'
    if isinstance(v, bool): return 't' if v else 'f'
    if isinstance(v, float):
        if not __import__('math').isfinite(v): raise ValueError('Nonfinite source number requires explicit contract')
        return str(decimal.Decimal.from_float(v))
    return str(v).replace('\\', '\\\\').replace('\t', '\\t').replace('\n', '\\n').replace('\r', '\\r')

def write_input(folder, out):
    manifest=json.loads((Path(__file__).resolve().parents[1]/'metadata/asset-manifest.json').read_text())
    assets=[a for a in manifest['assets'] if a['class']=='exact_existing_mirror']
    assert len(assets)==46
    out.write('\\set ON_ERROR_STOP on\n\\set VERBOSITY sqlstate\nBEGIN;\n')
    for a in assets:
        name=a['name']; assert re.fullmatch(r'[a-z_][a-z_0-9]*\.[a-z_][a-z_0-9]*',name)
        d=json.loads((folder/(name+'.json')).read_text()); cols=[c['name'] for c in a['columns']]
        if d.get('table')!=name or d.get('columns')!=cols or not d.get('snapshot_id'): raise ValueError('Invalid snapshot contract: '+name)
        if any(len(r)!=len(cols) for r in d['rows']): raise ValueError('Invalid row width: '+name)
        out.write('LOCK TABLE '+name+' IN ACCESS EXCLUSIVE MODE;\n')
        out.write("DO $$ BEGIN IF EXISTS(SELECT 1 FROM "+name+") THEN RAISE EXCEPTION 'Target must be empty'; END IF; END $$;\n")
        out.write('COPY '+name+' ('+','.join('"'+c.replace('"','""')+'"' for c in cols)+') FROM STDIN;\n')
        for row in d['rows']: out.write('\t'.join(copy_cell(v) for v in row)+'\n')
        out.write('\\.\n')
    out.write('COMMIT;\n')

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('snapshot_dir',type=Path);args=parser.parse_args()
    if not os.environ.get('PGSERVICE'): parser.error('Set PGSERVICE to your local libpq service; do not pass credentials on the command line')
    with tempfile.TemporaryFile(mode='w+',encoding='utf-8') as data:
        write_input(args.snapshot_dir,data);data.seek(0)
        result=subprocess.run(['psql','-X','-v','ON_ERROR_STOP=1','-q'],stdin=data,capture_output=True,text=True)
    # COPY diagnostics may contain source values. Suppress raw stderr intentionally.
    print('Mirror import committed' if result.returncode==0 else 'Mirror import failed and rolled back; inspect source contract and service configuration locally')
    return result.returncode
if __name__=='__main__': raise SystemExit(main())
