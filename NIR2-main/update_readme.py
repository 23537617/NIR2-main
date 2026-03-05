import re
import codecs

with codecs.open('README2.md', 'r', 'utf-8') as f:
    text = f.read()

def repl(m):
    # m.group(1) is 'invoke' or 'query'
    # m.group(2) is the json payload inside the single quotes, but with \`" instead of \"
    json_str = m.group(2).replace('\`\"', '\\\"')
    
    if m.group(1) == 'invoke':
        return f"peer chaincode invoke $env:ORDERER_ARGS $env:CHAINCODE_ARGS $env:PEER_ARGS -c '{json_str}'"
    else:
        return f"peer chaincode query $env:CHAINCODE_ARGS -c '{json_str}'"

# regex to find the bash -c wrapper
pattern = re.compile(r'bash -c \"peer chaincode (invoke|query) (?:.*?)-c \'(\{[^\}]+\})\'\"')

new_text = pattern.sub(repl, text)

with codecs.open('README2.md', 'w', 'utf-8') as f:
    f.write(new_text)

print('README2 updated successfully!')
