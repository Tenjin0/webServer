fs = require 'fs'
net = require 'net'
path = require 'path'


header = "HTTP/1.0 200 header
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

server = net.createServer options,(socket)->
	# parser = new HTTPParser(HTTPParser.remoteAddress)
	# console.log 'parserServer', parser
	socket.on 'connection',connectionSocket = ->
		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort
	socket.on 'connect',connectSocket = ->
		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->
		console.log  'socket : ' + socket.remoteAddress + ' DATA: -> ' + data
		# socket.write header

		filePath = path.join(__dirname, '/webroot/index.html')
		stat = fs.statSync(filePath)
		readStream = fs.createReadStream(filePath)
		socket.write header
		socket.write '\r\n'
		# socket.write readStream
		# socket.write filePath
		readStream.on 'open', ->
			readStream.pipe socket
			console.log 'readStream ouvert'
		readStream.on 'close', ->
			console.log 'readStream close'
			socket.end()
		# readStream.pipe socket
		# socket.write null
		# socket.write html
		# socket.end()
	socket.on 'error',errorSocket = ->
		console.log 'socket : error'
	socket.on 'close',closeSocket = ->
		console.log 'socket : close'


server.listen 3333,'patrice', listenCallback = ->
	address = server.address()
	console.log 'server bound',address

	server.on 'connection',connectionServer = (sock)->
		remoteAddress = sock.remoteAddress
		remotePort = sock.remotePort
		console.log 'server : connection ',remoteAddress ,remotePort

		sock.on 'connect',connectSocket = ->
			console.log 'socket inside: connect'
		# sock.on 'data' , dataSocket = (data)->
		# 	console.log 'sock:on',data
			# array = data.split '\n'
			# console.log array[0]
			# sock.pipe header

			# sock.write header

			# sock.write html
			# filePath = path.join(__dirname, '/webroot/min.html')
			# stat = fs.statSync(filePath)

			# readStream = fs.createReadStream(filePath)

			# readStream.on 'open', openCallback = ->
				#body of the callback open:event
				# sock.write 'open:event', header

			# 	console.log 'readStream:open'
			# readStream.on 'error', errorCallback = ->
			# sock.write header
			# sock.end()
			# readStream.on 'close', closeCallback = ->
			# 	console.log 'readStream on:close'

			# readStream.pipe sock
			# console.log  'sock : DATA ', sock.remoteAddress, ': ', data
		sock.on 'error',errorSock = ->
			console.log 'sock inside: error'
		sock.on 'close',closeSock = ->
			console.log 'sock inside: close'


	server.on 'close',closeServer = ->
		console.log 'server : close'

