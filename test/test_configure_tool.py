#!/usr/bin/env python3

from pathlib import Path
from pprint import pprint
import pytest
import shutil
from linux_maker.src.toolbox.configure_tool import ConfigureTool as ct


env_data = [    
    {"VARIABLE": ("Defined",),
     "BRIDGE_IP": ("50.23",),
     "TAP_NAME_LIST": ("sdf\"88'as'/p0\"", "ta87'/4"),
     "BOARD_RPI3B": (1234,),
     "BRIDGE_NAME": ("'br0a'df'",  '/p"br"9',  "/r/'tbr 6'/df.txt")},    
]


@pytest.fixture(scope="module")
def cfg_path(request):
     return  {"src": Path(__file__).parent / "data/test-env.cfg",
              "backup": Path(__file__).parent / "data/bak-env.cfg",}


@pytest.fixture(scope="module", params=env_data)
def data(cfg_path, request): 
    #shutil.copyfile(cfg_path['src'], cfg_path['backup'])     
    yield request.param
    #shutil.copyfile(cfg_path['backup'], cfg_path['src'])  


@pytest.fixture 
def modify_cfg(cfg_path, data):
    ct.modify_config(cfg_path['src'], data)
    

@pytest.fixture 
def parse_cfg(cfg_path, data, modify_cfg):
    result = {}
    for k,v in ct.parse_config(cfg_path['src'], data.keys()).items():
        result[k] = v
        pprint(f"{k}:{v}")
    return result


def test_manipulate_cfg(parse_cfg, data):
    assert parse_cfg == data
    
     

if __name__ == '__main__':
    pytest.main(['-s', 'linux_maker/test/test_configure_tool.py::test_manipulate_cfg'])

