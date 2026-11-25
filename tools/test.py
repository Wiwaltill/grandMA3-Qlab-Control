"""Run actual Lua 5.4 tests using Lupa (pip install lupa), not a Python port."""
import os
from pathlib import Path
from lupa.lua54 import LuaRuntime
import xml.etree.ElementTree as ET
from zipfile import ZipFile
import base64

root=Path(__file__).resolve().parents[1]
os.chdir(root)
lua=LuaRuntime()
lua.execute((root/'tests/run.lua').read_text())
lua.execute((root/'tests/integration.lua').read_text())
component=lua.execute((root/'dist/QLab Control.lua').read_text())
assert callable(component)
print('Generated Lua component loads in Lua 5.4')

xml=ET.parse(root/'dist/QLab Control.xml').getroot()
assert xml.tag=='GMA3' and xml.attrib['DataVersion']=='2.5.1.1'
plugin=xml.find('UserPlugin')
assert plugin.attrib['Name']=='QLab Control'
components=plugin.findall('ComponentLua')
assert len(components)==1
assert 'FileName' not in components[0].attrib
content=components[0].find('FileContent')
blocks=content.findall('Block')
assert int(content.attrib['Size'])==len(blocks)
decoded=[base64.b64decode(b.attrib['Base64'],validate=True) for b in blocks]
assert all(len(b)==1024 for b in decoded[:-1])
embedded=b''.join(decoded)
assert embedded==(root/'dist/QLab Control.lua').read_bytes()
assert callable(lua.execute(embedded.decode('utf-8')))
filename='QLab Control.lua'
with ZipFile(root/'dist/QLab-Control-0.2.0-beta.8-import.zip') as archive:
    base='gma3_library/datapools/plugins/'
    assert archive.read(base+filename)==(root/'dist'/filename).read_bytes()
    assert archive.read(base+'QLab Control.xml')==(root/'dist/QLab Control.xml').read_bytes()
    assert [n for n in archive.namelist() if n.endswith('.xml')]==[base+'QLab Control.xml']
    assert archive.read('LICENSE')==(root/'LICENSE').read_bytes()
    assert archive.testzip() is None
print('Embedded XML source, Lua load, ZIP structure and license verified')
