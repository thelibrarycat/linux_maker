#!/usr/bin/env python3

import re
from collections.abc import Iterable
from typing import  Match


class FormatMatch:

    KEY = "KEY"
    ARRAY = "ARRAY" 
    SQUOTE = "SQUOTE"
    DQUOTE = "DQUOTE"   
    WORD = "WORD"
    COMMENT = "COMMENT"   
    

    def __init__(self):
        self.create_pattern()

      
    def create_pattern(self):
        self.key_format = re.compile(rf'\s*(?P<{FormatMatch.KEY}>[A-za-z_]\w*)=')
        self.squote_format = re.compile(rf'\'(?P<{FormatMatch.SQUOTE}>[^\']*)\'')
        self.dquote_format = re.compile(rf'"(?P<{FormatMatch.DQUOTE}>.*?)(?<!\\)"')
        self.comment_format = re.compile(rf'(?P<{FormatMatch.COMMENT}>(?<!^)(?<!\s)#)')  #match # that is not at beginning and not after a space 
        self.array_format = re.compile(rf'\(\s*(?P<{FormatMatch.ARRAY}>[^\(\)]*)\)\s*')
        self.word_format = re.compile(rf'(?P<{FormatMatch.WORD}>[^\s\(\)]+)\s*' )
 

    def mask(self, m: Match) -> str:
        substring = m.group(m.lastgroup)
        if m.lastgroup == FormatMatch.SQUOTE:                           
            self.compensation += 2
        elif m.lastgroup == FormatMatch.DQUOTE:
            self.compensation += 2                                       
            self.compensation += len(re.findall(r'\"', substring))      
            substring = substring.replace(r'\"','"')

        return substring.replace(' ', '\0').replace('#', '\1').replace(')', '\2')  \
               .replace('(', '\3').replace('\'', '\4').replace('"', '\5')
    

    def unmask(self, m: str) -> str:
        return m.replace('\0', ' ').replace('\1', '#').replace('\2', ')') \
               .replace('\3', '(').replace('\4', '\'').replace('\5', '"')

       
    def match_format(self, line: str) -> dict[str, str] | None:
        m = self.key_format.match(line)
        if m is None:
            return None        
        key = m.group(FormatMatch.KEY)

        self.compensation = 0                                #compenstae for the consuming of '' or "" or \"
        value_start_pos = m.end()
        words = line[value_start_pos:] 
        words = self.dquote_format.sub(self.mask, words)    #double quotes have a higher priority than single quotes
        words = self.squote_format.sub(self.mask, words)       
        words = self.comment_format.sub(self.mask, words)
        pos = words.find('#')
        value = words[:pos] 
        comment = line[value_start_pos + self.compensation + pos:] if pos != -1 else line[pos:]     
        
        if value.startswith('('):
            m = self.array_format.match(value)
            if m is None:
                return None 
            value = m.group(FormatMatch.ARRAY)
        else:
            m = self.word_format.match(value)
            if m is None:
                return None 
            value = m.group(FormatMatch.WORD)

        return {"key": key, "value": value, "comment": comment}       
        

    def match_value(self, value: str) ->  Iterable[str | bool | int]:                      
        array = []       
        for m in self.word_format.finditer(value):            
            word = self.unmask(m.group(FormatMatch.WORD))
            array.append(self.str_to_obj(word))         
        
        return tuple(array)
    

    def str_to_obj(self, e: str) -> str | bool | int:
        match e:
            case 'y'|'Y':
                return True
            case 'n'|'N':
                return False
            case e if e.isnumeric():
                return int(e)
            case _:
                return e
    
    
    def obj_to_str(self, e: str | bool | int) -> str:
        if type(e) is bool:            
            return 'y' if e else 'n'
        elif type(e) is str:
            e = e.replace('"', '\\"')        
            return f'"{e}"'
        else:
            return str(e)       
 


class ConfigureTool:

    @staticmethod
    def parse_config(file_name: str, keys: Iterable[str]=None) -> dict[str, Iterable[str | bool | int]]:
        env = {}
        is_specific = False    
        if keys is not None: 
            is_specific = True

        with open(file_name, 'r', encoding='utf-8') as f:
            pattern = FormatMatch()
            for line in f:          
                if result := pattern.match_format(line):
                    if not is_specific or (is_specific and result["key"] in keys):                    
                        env[result["key"]] = pattern.match_value(result["value"])                  
        
        return env


    @staticmethod
    def modify_config(file_name: str, content: dict[str,Iterable[str | bool | int]]):
        file_data = ""       
        with open(file_name, "r", encoding="utf-8") as f:
            pattern = FormatMatch()
            for line in f:            
                if result := pattern.match_format(line):           
                    key = result["key"] 
                    if key in content.keys(): 
                        value_tuple = content[key]            
                        value = ' '.join(pattern.obj_to_str(e) for e in value_tuple)               
                        if len(value_tuple) > 1:  
                            value = f'({value})'                           
                        line = f'{key}={value}    {result["comment"]}'  
                file_data += line

        with open(file_name, "w",encoding="utf-8") as f:
            f.write(file_data)



