"""Build a self-contained Lua component and a reproducible development ZIP.

No speculative grandMA XML wrapper: use the component editor until a native
2.5.1.1 export fixture is available and its round-trip has been tested.
"""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.0-dev.1'

def build():
    out = ROOT / 'dist'
    out.mkdir(exist_ok=True)
    core = (ROOT / 'src/core.lua').read_text()
    adapter = (ROOT / 'src/ma.lua').read_text()
    source = ('-- QLab Control '+VERSION+'; development build, not console validated.\n'
              'local core=(function()\n'+core+'\nend)()\n'
              'local adapter=(function()\n'+adapter+'\nend)()\n'
              'return function(display_handle, argument)\n'
              ' local ok,err=pcall(function() adapter.new(core,_G).run(argument) end)\n'
              ' if not ok then ErrPrintf("QLab Control: %s",tostring(err)) end\n'
              'end\n')
    lua = out / 'QLab Control.lua'
    lua.write_text(source)
    files = {'QLab Control.lua': lua, 'README.md': ROOT/'README.md',
             'LICENSE': ROOT/'LICENSE'}
    files.update({'docs/'+p.name:p for p in sorted((ROOT/'docs').glob('*.md'))})
    archive = out/f'QLab-Control-{VERSION}-source-preview.zip'
    with ZipFile(archive, 'w', compression=ZIP_DEFLATED) as z:
        for name,path in sorted(files.items()):
            info=ZipInfo(name, date_time=(2026,1,1,0,0,0))
            info.compress_type=ZIP_DEFLATED
            info.external_attr=0o100644 << 16
            z.writestr(info,path.read_bytes())
    print(archive)

if __name__ == '__main__':
    build()
