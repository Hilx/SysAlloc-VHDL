
f = "11"
p = "01"
e = "00"

d0 = p
d1 = e + p
d2 =e+e+e+f
d3 = e + e + e + e + e + e + f + f
fill = "00"

def gen():
    tree_out = fill + d3 + d2 + d1 + d0
    print(tree_out)
    
gen();