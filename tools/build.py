"""Build Lua, grandMA3 XML entry point and reproducible import ZIP.

UserPlugin/ComponentLua follow local MA examples and the official Plugins docs.
No local third-party source code is bundled.
"""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.0-dev.4'

def build():
    out = ROOT / 'dist'
    out.mkdir(exist_ok=True)
    core = (ROOT / 'src/core.lua').read_text()
    adapter = (ROOT / 'src/ma.lua').read_text()
    guide = (ROOT / 'src/guide.lua').read_text()
    source = ('-- QLab Control '+VERSION+'; development build, not console validated.\n'
              'local core=(function()\n'+core+'\nend)()\n'
              'local adapter=(function()\n'+adapter+'\nend)()\n'
              'local guide=(function()\n'+guide+'\nend)()\n'
              'return function(display_handle, argument)\n'
              ' local ok,err=pcall(function() adapter.new(core,_G,guide).run(argument) end)\n'
              ' if not ok then ErrPrintf("QLab Control: %s",tostring(err)) end\n'
              'end\n')
    lua = out / 'QLab Control.lua'
    lua.write_text(source)
    root = ET.Element('GMA3', DataVersion='2.5.1.1')
    plugin = ET.SubElement(root, 'UserPlugin', Name='QLab Control', Version='0.1.0.4')
    ET.SubElement(plugin, 'ComponentLua', Name='QLab Control', FileName=lua.name)
    ET.indent(root, space='    ')
    xml = out / 'QLab Control.xml'
    ET.ElementTree(root).write(xml, encoding='utf-8', xml_declaration=True)
    base='gma3_library/datapools/plugins/'
    files = {base+lua.name: lua, base+xml.name: xml, 'README.md': ROOT/'README.md',
             'LICENSE': ROOT/'LICENSE'}
    files.update({'docs/'+p.name:p for p in sorted((ROOT/'docs').glob('*.md'))})
    archive = out/f'QLab-Control-{VERSION}-import.zip'
    with ZipFile(archive, 'w', compression=ZIP_DEFLATED) as z:
        for name,path in sorted(files.items()):
            info=ZipInfo(name, date_time=(2026,1,1,0,0,0))
            info.compress_type=ZIP_DEFLATED
            info.external_attr=0o100644 << 16
            z.writestr(info,path.read_bytes())
    print(archive)

if __name__ == '__main__':
    build()
