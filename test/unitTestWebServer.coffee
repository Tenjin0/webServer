Server = require '../class'

# console.log Server
header = 'GET /images HTTP/1.1\r\nHost: localhost:9000\r\n'
header2 = '\r\n22222'
net = require 'net'
socket = new net.Socket()

socket.connect 9000,'localhost', ->
  console.log 'connected to server!',socket.remoteAddress,socket.remotePort
  socket.write  header
  socket.write  header2

socket.on 'data', (data)->
  console.log "<<<<<< DATA >>>>>>"
  console.log data.toString()
  socket.end()
socket.on 'error',(err)->
  console.log 'client : error',err
socket.on 'end', ->
  console.log 'disconnected from server'

