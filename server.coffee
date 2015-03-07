# MODULES RECQUIS
fs = require 'fs'
net = require 'net'
path = require 'path'
# CONSTANTES
conf = JSON.parse(fs.readFileSync('conf/local.json'
	, 'utf8'))

ROOT = path.join( __dirname , conf.contentFolderPath)

DEFAULT_PROTOCOL = 'HTTP/1.0'
DEFAULT_EXTENSION = '.html'

# REGEXS
FIRST_LINE_REGEX = new RegExp "(GET|POST|HEAD)[ ]([\/].*[ ]){1,}HTTP\/1\.[0-9]"
AUTHORIZED_PATH = new RegExp "#{ROOT}.*"
METHOD_REGEX  = new RegExp "(GET|POST|HEAD)"

# DATAS
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
	403 : "Forbidden Acces"
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

# OBJETS AND FUNCTIONS
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
</html>\n
"

createAbsolutePath = (relativePath)->
	try
		stats = fs.statSync(path.join ROOT,relativePath)
		if stats.isDirectory() && fs.existsSync(path.join ROOT, relativePath, 'index.html')
			temp = path.join ROOT, relativePath, 'index.html'
		else
			temp = path.join ROOT, relativePath
		console.log relativePath, temp
		temp
	catch err
		console.log err
		path.join ROOT,relativePath

parseStatusLine = (data)->

	firstLine =  (data.toString().split "\r\n")[0]
	if FIRST_LINE_REGEX.test firstLine
		requestLineArray = firstLine.split " "
		requestLineJSON =
			method : requestLineArray[0] # firstLine.substring 0,indexOf(' ')
			path : createAbsolutePath requestLineArray[1]
			protocol : requestLineArray[2]

		requestLineJSON
	else
		null

createResponseHeader = ( code, ext, fileLength) ->
	responseHeader =
		statusLine : "#{DEFAULT_PROTOCOL} #{code} #{statusMessages[code]}"
		fields :
			'content-Type' : contentTypeMap[ext] ? 'text/plain'
			'Date' : new Date()
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
			socket.end((createErrorHtml statusCode)['body'])


# Options for the server
ServerOptions =
	allowHalfOpen: false,
	pauseOnConnect: false

# SERVER
server = net.createServer ServerOptions, (socket)->

	socket.on 'data' ,(data)->
		statusCode = 400
		statusLine = parseStatusLine data
		if statusLine
			extension = path.extname statusLine['path'].toLowerCase()
			fs.stat statusLine['path'], (err,stats)->
				if err
					statusCode = 404
				else if stats.isDirectory() || !AUTHORIZED_PATH.test statusLine['path']
					statusCode = 403
				else if stats.isFile()
					statusCode = 200
					fileSize = stats["size"]
					readStream = fs.createReadStream statusLine['path']
					readStream.on 'end', ->
						socket.end()

				if !fileSize
					extension = DEFAULT_EXTENSION
					fileSize = Buffer.byteLength((createErrorHtml statusCode)['body'], 'utf8')

				# Create responseHeader
				responseHeader = createResponseHeader statusCode, extension,fileSize
				console.log statusLine['path']
				console.log responseHeader.toString()
				# Send the response (header + body)
				sendResponse socket, responseHeader, statusCode, readStream
		else
			responseHeader = createResponseHeader statusCode
			sendResponse socket, responseHeader, statusCode

		socket.on 'error',(err) ->
			console.log 'socket: error',err
		# socket.on 'close', ->
			# console.log 'socket: close'

server.listen 9000,'localhost'
