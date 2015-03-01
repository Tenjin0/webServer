fs = require 'fs'
net = require 'net'
path = require 'path'
HTTPParser = process.binding('http_parser').HTTPParser

root = __dirname + '/webroot'
httpRequest = 
	"GET / HTTP/1.0\r\n
	Host: patrice:3333\r\n
	Connection: keep-alive\r\n
	Cache-Control: max-age=0\r\n
	Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\n
	User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/40.0.2214.111 Chrome/40.0.2214.111 Safari/537.36\r\n
	Accept-Encoding: gzip, deflate, sdch\r\n
	Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4\r\n
	"

html = 
"<!DOCTYPE html>
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

statusCode = 
	"200" : "OK"
	"201" : "Created"
	"202" : "Accepted"		
	"204" : "No Content"
	"301" : "Moved Permanently"
	"302" : "Moved Temporarily"
	"304" : "Not Modified"
	"400" : "Bad Request"
	"401" : "Unauthorized"
	"403" : "Forbidden"
	"404" : "Not Found"
	"500" : "Internal Server Error"
	"501" : "Not Implemented"
	"502" : "Bad Gateway"
	"503" : "Service Unavailable"

regex = "GET |POST |HEAD \/.* HTTP\/1.[0..9]"
testHeader = 
	"GET / HTTP/1.0\r\n"


console.log 'match',testHeader.match regex
# HTTPParser = process.binding('http_parser').HTTPParser
# methods = HTTPParser.methods
# Transform = require('stream').Transform
requestLine = (data)->
	array = dataToArray data
	# console.log 'array', array
	requestLineArray = array[0]
	# console.log requestLineArray
	requestLineJSON =
		"method" : requestLineArray[0]
		"path" : requestLineArray[1]
		"protocol" : requestLineArray[2]
	return requestLineJSON

isNotEmpty = (element)->
	return !(element is '')

dataToArray = (data)->
	array =  data.toString().split "\r\n"
	array = array.filter isNotEmpty	# console.log 'array',array
	for i in [0..array.length-1]
		array[i] = array[i].split " "
	return array

arrayContains = (array, data)->
	for value in array
		if value == data
			return true
	false

constructHeader = (protocole,code,ext, lengthFile) ->
	contentLength = if length then "Content-Length:" + lengthFile+ "\r\n" else ""
	protocole+ " " + code + " " +  statusCode[code] + "\r\n" + "Content-Type: text/"+ ext + "\r\n" + contentLength + "Connection: close"+ "\r\n"+ "\r\n"

requestLineHeaderJSON = requestLine httpRequest
console.log 'firstLineHeaderJSON', requestLineHeaderJSON
chemin = requestLineHeaderJSON['path']
chemin = if chemin is '/' then 'index.html' else chemin
console.log 'path : ', chemin

server = net.createServer options,(socket)->
	parser = new HTTPParser(HTTPParser.RESPONSE)
	console.log 'parserServer', parser

	socket.on 'connection',connectionSocket = ->
		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort + "\n"
	socket.on 'connect',connectSocket = ->
		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->
		# console.log  'socket : ' + socket.remoteAddress + ' DATA: -> ' + data
		# socket.write header
		# firstLineHeaderJSON = firstLineHeader data
		# console.log 'firstLineHeaderJSON', firstLineHeaderJSON
		# parser = new HTTPParser(HTTPParser.httpRequest)
		# console.log 'parserServer', parser
		# parser.onHeadersComplete = (res) ->
  #   		console.log('onHeadersComplete')
  #   		console.log(res)
		
		# parser.execute(data, 0, data.length)
		requestLineHeaderJSON = requestLine data
		chemin = requestLineHeaderJSON['path']
		console.log chemin.match "\.\.\/.*"
		if chemin.match "\.\.\/.*" 
			chemin = if chemin is '/'|| '' then 'index.html' else chemin
			filePath = path.join(root , chemin)
			extension = (path.extname filePath.toLowerCase()).replace '.', ''
			console.log 'search ', filePath, extension
			stats = fs.statSync(filePath)
			if stats.isFile()
				header = constructHeader requestLineHeaderJSON['protocol'],"200", extension,stats["size"]
				readStream = fs.createReadStream(filePath)
				socket.write header
				socket.write '\r\n\r\n'
			else
				header = constructHeader requestLineHeaderJSON['protocol'],"200", extension
			readStream.on 'open', ->
				console.log 'readStream ouvert'
				if requestLineHeaderJSON['method'].toUpperCase() is 'GET' ||  requestLineHeaderJSON['method'].toUpperCase() is 'POST'
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

server.listen 9000,'localhost'
