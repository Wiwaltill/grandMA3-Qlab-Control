"""Run actual Lua 5.4 tests using Lupa (pip install lupa), not a Python port."""
import os
from pathlib import Path
from lupa.lua54 import LuaRuntime

root=Path(__file__).resolve().parents[1]
os.chdir(root)
lua=LuaRuntime()
lua.execute((root/'tests/run.lua').read_text())
component=lua.execute((root/'dist/QLab Control.lua').read_text())
assert callable(component)
print('Generated Lua component loads in Lua 5.4')
