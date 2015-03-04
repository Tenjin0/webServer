net = require 'net'
fs = require 'fs'
path = require 'path'

www = './webroot'

htmlError = '<!DOCTYPE HTML>
	<html>
		<head>
		</head>
		<body>
			La page que vous recherchez n\'existe pas
		</body>
	</html>'


contentTypeArray =
	html: 'text/html'
	map: 'text/plain'
	css: 'text/css'
	js: 'application/javascript'
	jpg: 'image/jpeg'
	jpeg: 'image/jpeg'
	mp3: 'audio/mp3'
	mp4: 'video/mpeg'

# console.log contentTypeArray[null]
#reqHeader
statusLine = null
method = null
protocol = null
# filePath = null

#resHeader
# extension = null
contentType = null


# mes OUMPA-LOUMPA
processReqHeader = (reqHeader)->
	str = reqHeader.toString 'utf8'
	statusLine = str.substr 0, str.indexOf('\r\n')
	method = statusLine.substr 0, statusLine.indexOf(' ')
	protocol = statusLine.substr statusLine.indexOf('HTTP') #inutile
	filePath = statusLine.substring statusLine.indexOf(method) + method.length + 1, statusLine.indexOf ' HTTP'

processResHeader = (realPath)->
	extension = path.extname realPath
	extension = extension.substr 1
	contentType = contentTypeArray[extension]


processResponse = (file,respHeader, fileStream, socket)->
	if !(contentType is undefined)
		socket.write respHeader, ->
			console.log file,respHeader
			fileStream.pipe socket
			fileStream.on 'end', cbFileStream =->
				socket.end()
	else
		socket.end()


# Willy Wonka
server = net.createServer (socket)->
	socket.on 'data', cbSocketOnDATA = (reqHeader)->

		filePath = processReqHeader reqHeader
		console.log 'filePath', filePath
		realPath = path.join(www, if filePath is '/' then 'index.html' else filePath)

		content = processResHeader realPath

		respHeader = "
					HTTP/1.0 200 OK\r\nContent-Type:#{contentType}\r\n\r\n"

		fileStream = fs.createReadStream realPath

		processResponse filePath, respHeader, fileStream, socket
	# socket.on 'open', ->
	# 	console.log 'socket : open'
	# socket.on 'error', ->
	# 	console.log 'socket : error'
	# socket.on 'close', ->
	# 	console.log 'socket : close'

server.listen 3333, 'localhost', ->
	console.log 'server ONline\r\n'

