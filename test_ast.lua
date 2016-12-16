node = require'batch.node'

n=node()
n2=n:add(5, 8, 7, 5)
n2[0]=n
w=n:walker()
n:add(5, 8, 7, 3)[5]=n2

print(n, n2, w(5,8), w(7), w(3), w(5))

print(w(0, 5, 8, 7, 5), n2)
print(w(0, 5, 8, 7, 3, 5), n2)

print(n:get(5,8), n:get(5,8):walker())