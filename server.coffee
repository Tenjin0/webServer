# MODULES RECQUIS
fs = require 'fs'
net = require 'net'
path = require 'path'

# CONSTANTTE
obj = JSON.parse(fs.readFileSync('conf/local.json', 'utf8'))
ROOT = path.join( __dirname , obj.contentFolderPath)
console.log  ROOT
DEFAULT_PROTOCOL = 'HTTP/1.0'
DEFAULT_EXTENSION = '.html'

# REGEX
FIRST_LINE_REGEX = new RegExp "(GET|POST|HEAD)[ ]([\/].*[ ]){1,}HTTP\/1\.[0-9]"
AUTHORIZED_PATH = new RegExp "#{ROOT}.*"
METHOD_REGEX  = new RegExp "(GET|POST|HEAD)"


# DATA
statusMessages =
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

contentTypeMap =
	'.jpg': 'image/jpg',
	'.jpeg': 'image/jpeg',
	'.png': 'image/png',
	'.bmp': 'image/bmp',
	'.gif': 'image/gif',
	'.js': 'application/javascript',
	'.mp4': 'video/mp4',
	'.mp3': 'audio/mp3',
	'.html': 'text/html',
	'.css': 'text/css'


# OBJET AND FUNCTION
createErrorHtml = (code) ->
	body : "<!DOCTYPE html>
<html>
<head>
	<title>Webserver Test</title>
	<meta charset='utf-8'>
</head>
<body>
	<H2>#{code} #{statusMessages[code]}</H2>
</body>
</html>
"


parseStatusLine = (data)->

	firstLine =  (data.toString().split "\r\n")[0]
	if FIRST_LINE_REGEX.test firstLine
		requestLineArray = firstLine.split " "
		requestLineJSON =
			method : requestLineArray[0] # firstLine.substring 0,indexOf(' ')
			path : if path.normalize(requestLineArray[1]) is '/' then 'index.html' else requestLineArray[1]
			protocol : requestLineArray[2]

		requestLineJSON
	else
		null


createResponseHeader = ( code, ext, fileLength) ->
	responseHeader =
		statusLine : "#{DEFAULT_PROTOCOL} #{code} #{statusMessages[code]}"
		fields :
			'content-Type' : if ext && contentTypeMap[ext] then contentTypeMap[ext] else 'text/plain'
			'Content-Length' : fileLength ? 0
			'Connection' : 'close'

	toString : ->
		str = "#{responseHeader['statusLine']}\r\n"
		for i,v of responseHeader['fields']
			str += i + ': ' + v + "\r\n"
		str + '\r\n'

sendResponse = (socket, header, statusCode,readStream) ->
	socket.write header.toString(),->
		if readStream
			readStream.pipe socket
		else
			socket.write (createErrorHtml statusCode)['body']+ '\n'
			socket.end()

# Options for the server
ServerOptions =
	allowHalfOpen: false,
	pauseOnConnect: false

# SERVER
server = net.createServer ServerOptions, (socket)->

	socket.on 'connection', ->
		console.log 'socket : connect'

	socket.on 'data' ,(data)->
		statusCode = 400
		statusLine = parseStatusLine data
		if statusLine
			# remove unnecessary ../
			absolutePath = path.join(ROOT , statusLine['path'])
			# console.log absolutePath
			extension = path.extname absolutePath.toLowerCase()

			fs.stat absolutePath, (err,stats)->
				if err
					statusCode = 404
				else if stats.isDirectory() || !AUTHORIZED_PATH.test absolutePath
					statusCode = 403
				else if stats.isFile()
					statusCode = 200
					fileSize = stats["size"]
					readStream = fs.createReadStream absolutePath
					readStream.on 'end', ->
						socket.end()

				if !fileSize
					extension = DEFAULT_EXTENSION
					fileSize = Buffer.byteLength((createErrorHtml statusCode)['body'], 'utf8')

				# Create responseHeader
				responseHeader = createResponseHeader statusCode, extension,fileSize
				# Send the response (header + body)
				sendResponse socket, responseHeader, statusCode, readStream
		else
			responseHeader = createResponseHeader statusCode
			sendResponse socket, responseHeader, statusCode

		socket.on 'error',(err) ->
			console.log 'socket: error',err
		socket.on 'close', ->
			# console.log 'socket: close'

server.listen 9000,'localhost'
