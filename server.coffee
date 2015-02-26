fs = require 'fs'
net = require 'net'
path = require 'path'

ok = "HTTP/1.0 200 OK\n" + "Content-Type: text/html\n"
# HTTPParser = process.binding('http_parser').HTTPParser
# methods = HTTPParser.methods
# Transform = require('stream').Transform

server = net.createServer (socket)->
	# parser = new HTTPParser(HTTPParser.remoteAddress)
	# console.log 'parserServer', parser
	socket.on 'connection',connectionSocket = ->
		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort
	socket.on 'connect',connectSocket = ->
		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->
		# socket.write ok
		# filePath = path.join(__dirname, '/webroot/index.html')
		# stat = fs.statSync(filePath)
		# readStream = fs.createReadStream(filePath)
		# readStream.pipe socket
		# console.log  'socket : DATA ' + socket.remoteAddress + ': ' + data
	socket.on 'error',errorSocket = ->
		console.log 'socket : error'
	socket.on 'close',closeSocket = ->
		console.log 'socket : close'

server.listen 8124,'localhost', listenCallback = ->
	address = server.address()
	console.log 'server bound',address

	server.on 'connection',connectionServer = (sock)->
		remoteAddress = sock.remoteAddress
		remotePort = sock.remotePort
		console.log 'server : connection ',remoteAddress ,remotePort

		sock.on 'connect',connectSocket = ->
			console.log 'socket inside: connect'
		sock.on 'data' , dataSocket = (data)->
			array = data.split '\n'
			console.log array[0]
			sock.pipe ok

			filePath = path.join(__dirname, '/webroot/index.html')
			stat = fs.statSync(filePath)
			readStream.on('open', function () {
			#This just pipes the read stream to the response object (which goes to the client)
    readStream.pipe(res);
});

# This catches any errors that happen while creating the readable stream (usually invalid names)
readStream.on('error', function(err) {
res.end(err);
});
			readStream.pipe sock
			console.log  'sock : DATA ','encoding', sock.remoteAddress, ': ', data
			
		sock.on 'error',errorSocket = ->
			console.log 'socket inside: error'
		sock.on 'close',closeSocket = ->
			console.log 'socket inside: close'


	server.on 'close',closeServer = ->
		console.log 'server : close'

