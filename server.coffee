fs = require 'fs'
net = require 'net'
path = require 'path'


root = __dirname + '/webroot'
httpRequest = "GET / HTTP/1.0\r\n
Host: patrice:3333\r\n
Connection: keep-alive\r\n
Cache-Control: max-age=0\r\n
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\n
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/40.0.2214.111 Chrome/40.0.2214.111 Safari/537.36\r\n
Accept-Encoding: gzip, deflate, sdch\r\n
Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4\r\n
"
header200 = "HTTP/1.0 200 header
\n" + "Content-Type: text/html\n"
header404 = "HTTP/1.0 404 badRequest
\n" + "Content-Type: text/html\n"
html = "<!DOCTYPE html>
<html>
<head>
	<title>Webserver Test</title>
	<meta charset='utf-8'>
</head>
<body>
	Ceci est le body
</body>
</html>
"
options =
  allowHalfOpen: false,
  pauseOnConnect: false

# HTTPParser = process.binding('http_parser').HTTPParser
# methods = HTTPParser.methods
# Transform = require('stream').Transform
firstLineHeader = (data)->
	array = dataToArray data
	# console.log 'array', array
	firstLineHeaderArray = array[0]
	# console.log firstLineHeaderArray
	firstLineHeaderToJSON =
		method : firstLineHeaderArray[0]
		path : if firstLineHeaderArray.length == 3 then firstLineHeaderArray[1] else null
		protocol : if firstLineHeaderArray.length == 3 then firstLineHeaderArray[2] else firstLineHeaderArray[1]

	return firstLineHeaderToJSON
isEmpty = (element)->
	return !(element is '')

dataToArray = (data)->
	array =  data.toString().split "\r\n"
	array = array.filter isEmpty
	# console.log 'array',array
	for i in [0..array.length-1]
		array[i] = array[i].split " "
	return array
firstLine = (array)->
	return array[0]

arrayContains = (array, data)->
	for value in array
		if value == data
			return true
	false

firstLineHeaderJSON = firstLineHeader httpRequest
console.log 'firstLineHeaderJSON', firstLineHeaderJSON
chemin = firstLineHeaderJSON['path']
chemin = if chemin is '/' then 'index.html' else chemin
console.log 'path : ', chemin

server = net.createServer options,(socket)->
	# parser = new HTTPParser(HTTPParser.remoteAddress)
	# console.log 'parserServer', parser
	socket.on 'connection',connectionSocket = ->
		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort + "\n"
	socket.on 'connect',connectSocket = ->
		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->
		# console.log  'socket : ' + socket.remoteAddress + ' DATA: -> ' + data
		# socket.write header
		# firstLineHeaderJSON = firstLineHeader data
		# console.log 'firstLineHeaderJSON', firstLineHeaderJSON

		firstLineHeaderJSON = firstLineHeader data
		chemin = firstLineHeaderJSON['path']
		chemin = if chemin is '/' then 'index.html' else chemin

		filePath = path.join(root , chemin)
		console.log 'search ', filePath
		# stat = fs.statSync(filePath)
		readStream = fs.createReadStream(filePath)
		socket.write header200
		socket.write '\r\n'
		socket.write '\r\n'
		# socket.write html
		# socket.write readStream
		# socket.write filePath
		readStream.on 'open', ->
			console.log 'readStream ouvert'
			readStream.pipe socket
			# readStream.close()
		readStream.on 'close', ->
			console.log 'readStream close'
			# socket.end()
		# readStream.pipe socket
		# socket.write null
		# socket.end()
	socket.on 'error',errorSocket = ->
		console.log 'socket : error'
	socket.on 'close',closeSocket = ->
		console.log 'socket : close'


server.listen 3333,'patrice'
