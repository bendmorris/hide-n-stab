import json
import sys
path = sys.argv[1]
try: SCALE = eval(sys.argv[2])
except: SCALE = 1/0.6

with open(path) as input_file:
    json_data = json.load(input_file)

def traverse_dict(x):
    if isinstance(x, list):
        for i in x:
            traverse_dict(i)
    elif isinstance(x, dict):
        for (key, value) in x.items():
            if key in ('x', 'y', 'length', 'width', 'height'):
                x[key] = round(x[key] * SCALE, 2)
            elif isinstance(value, dict) or isinstance(value, list):
                traverse_dict(value)

'''for bone in json_data['bones']:
    print bone
    for var in ('x', 'y', 'length'):
        if var in bone: bone[var] *= SCALE

for animation in json_data['animations'].items():
    print animation'''

traverse_dict(json_data)

json.dump(json_data, sys.stdout)