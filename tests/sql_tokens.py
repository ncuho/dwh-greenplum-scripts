import hashlib,json,re

def canonical(s):
 # SQL token identity, ignoring layout and case of unquoted identifiers. Dollar bodies are SQL here.
 pattern=r"--[^\n]*|/\*[\s\S]*?\*/|\$[A-Za-z_0-9]*\$|'(?:''|[^'])*'|\"(?:\"\"|[^\"])*\"|[A-Za-z_][A-Za-z_0-9$]*|(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|[^\s]"
 tokens=[]
 for x in re.findall(pattern,s):
  if x.startswith(('--','/*')) or re.fullmatch(r'\$[A-Za-z_0-9]*\$',x):continue
  tokens.append(x if x.startswith(("'",'"')) else x.lower())
 return tokens

def digest(s):return hashlib.sha256(json.dumps(canonical(s),ensure_ascii=False,separators=(',',':')).encode()).hexdigest()
