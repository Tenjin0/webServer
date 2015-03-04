# http://rzrsharp.net/2011/06/27/what-does-coffeescripts-do-do.html
fs = require 'fs'


statusCode =
	200 : "OK"
	201 : "Created"
	202 : "Accepted"
	204 : "No Content"
	301 : "Moved Permanently"
	302 : "Moved Temporarily"
	304 : "Not Modified"
	400 : "Bad Request"
	401 : "Unauthorized"
	403 : "Forbidden"
	404 : "Not Found"
	500 : "Internal Server Error"
	501 : "Not Implemented"
	502 : "Bad Gateway"
	503 : "Service Unavailable"


# for index, value of statusCode

# 	(fn = (num, value )->
# 		setTimeout (->
# 			console.log num, value
# 		) ,0
# 	) index, value

# number = 1
# do ->
# 	((num) ->
# 		setTimeout (->
# 			console.log 'numero', num
# 		), 100
# 	) number
# 	number++

# that = this
# that.foo = 'bar'
# process.nextTick (->
# 	console.log 'this ' + this.foo + ' and that ' + that.foo
# )
errorTab = for index,value of statusCode
	parseInt index
# console.log  errorTab
str = ''
closure = []

fn = ->
	setTimeout ( ->
		console.log str
	), 0
create = ->
	for i in [0..10] by 1
		str = str.concat("i:for = ", i, '\n')
		# console.log str
		(closure[i] = (tmp)->
			setTimeout ( ->
				str = str.concat "i = " ,  i ,"\n"),0
		)(i)
run = ->
	for f in closure
		f()
create()
# run()
# fn()
# (do (i) ->
# 	console.log i) for i in [0..5]
# ((do (msg) -> -> console.log msg) for i in [0..5])
newTab = errorTab.map (value) ->
	value * 2

# console.log newTab


file = fs.createReadStream('./min1.html')
stats = fs.statSync("./min1.html")

# dataSize = Buffer.byteLength(file, 'utf8')
dataSize = stats["size"]
console.log dataSize
file.on 'readable', ->
	console.log 'readable : fire! !! !!!!'
	data = file.read(dataSize)
	if data
		console.log('readable size = ', data.length)
		console.log(data.toString())
