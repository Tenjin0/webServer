Server = require '../class'

# console.log Server
header =
	'GET /iframe HTTP/1.1\r\n' #Host: localhost:9000\r\n'
net = require 'net'
socket = new net.Socket()

socket.connect 9000,'localhost', ->
	console.log 'connected to server!',socket.remoteAddress,socket.remotePort
	socket.write  header
socket.on 'data', (data)->
	console.log "<<<<<< DATA >>>>>>"
	console.log data.toString()
	socket.end()
socket.on 'error',(err)->
	console.log 'client : error',err
socket.on 'end', ->
	console.log 'disconnected from server'

