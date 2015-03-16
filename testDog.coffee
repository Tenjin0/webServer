Dog = require './dog'
server = require './server'
doggy = new Dog 'Tony'

console.log doggy.getName()
doggy.prepare_fetch_later()
doggy.retrieveName 'name', (name) ->
	console.log doggy.getName()
obj = []
str = 'Cookie: CUSTOMER=WILE_E_COYOTE; PART_NUMBER=ROCKET_LAUNCHER_0001; SHIPPING=FEDEX'
COOKIE_REGEX = new RegExp "Cookie: (([^;]*=[^;]*;)*[^;]*=[^;]*)$"

match = str.match COOKIE_REGEX
console.log  'match Cookies: ', split = match[1].split("; ")
NAME_VALUE_REGEX = new RegExp "(.*)=(.*)"

console.log 'split',split
cookie = []
for i in split
	match2 = i.match NAME_VALUE_REGEX
	# console.log  match2
	cookie[match2[1]] = match2[2]
	# cookie.push(obj)
	# else
		# console.log mat
console.log 'cookie', cookie
