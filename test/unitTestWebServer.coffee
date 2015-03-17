Server = require '../class'

# console.log Server

r = new Server.Response()
# console.log  r

a = new Server.SessionCookie()
cookies = [a]
cookies2 = []
c = new Server.Cookie('name','toto')
d = new Server.Cookie('lastName','titi')
cookies.push c
cookies.push d
console.log cookies2.concat cookies
