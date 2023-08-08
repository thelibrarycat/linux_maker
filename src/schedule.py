#!/usr/bin/python3

from enum import Enum
from collections.abc import Iterable
from toolbox.configure_tool import ConfigureTool as ct




class InputType(Enum):
    TRACK = 'track'
    ALBUM = 'album'
    ARTIST = 'atrist'

#InputType.ARTIST == InputType.ARTIST










class Workflow:

    def __init__(self, file_name: str):
        self.env: dict[str, Iterable[str | bool | int]] = {}
        self.file_name = file_name
        self.parse_environment_variables()
    

    def parse_environment_variables(self):    
        pass
      
       

if __name__ == '__main__':
    w = Workflow()
    for k,v in w.env.items():
        print(k,v)




