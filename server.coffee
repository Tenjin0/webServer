net = require 'net'

server = net.createServer (socket)->

	socket.on 'connection',connectionSocket = ->
		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort
	socket.on 'connect',connectSocket = ->
		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->
		console.log  'socket : DATA ' + socket.remoteAddress + ': ' + data
		socket.write 'socket :you said ' + data
	socket.on 'error',errorSocket = ->
		console.log 'socket : error'
	socket.on 'close',closeSocket = ->
		console.log 'socket : close'

server.listen 8124,'10.0.0.80', listenCallback = ->
	address = server.address()
	console.log 'server bound',address

	server.on 'connection',connectionServer = (sock)->
		remoteAddress = sock.remoteAddress
		remotePort = sock.remotePort
		console.log 'server : connection ',remoteAddress ,remotePort

		sock.on 'connect',connectSocket = ->
			console.log 'socket inside: connect'
		sock.on 'data' , dataSocket = (data)->
			console.log  'sock : DATA ','encoding', sock.remoteAddress, ': ', data
			sock.write 'sock : you said \n' + data
		sock.on 'error',errorSocket = ->
			console.log 'socket inside: error'
		sock.on 'close',closeSocket = ->
			console.log 'socket inside: close'


	server.on 'close',closeServer = ->
		console.log 'server : close'

