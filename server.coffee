# MODULES RECQUIS
fs = require 'fs'
net = require 'net'
path = require 'path'
# CONSTANTES
conf = JSON.parse(fs.readFileSync('conf/local.json'
	, 'utf8'))

ROOT = path.join( __dirname , conf.contentFolderPath)
ind = 0
DEFAULT_PROTOCOL = 'HTTP/1.0'
DEFAULT_EXTENSION = '.html'

# REGEXS
FIRST_LINE_REGEX = new RegExp "(GET|POST|HEAD)[ ]([\/].*[ ]){1,}HTTP\/1\.[0-9]"
AUTHORIZED_PATH = new RegExp "#{ROOT}.*"
host = "Host"
REQUEST_HOST_REGEX = new RegExp "#{host}: "
REQUEST_PATH_REGEX = new RegExp "#{"\/$"}"
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
	length : ->
		Buffer.byteLength(@body, 'utf8')
# Determine statusCode and FileLength
checkRequestPath = (requestLine,callback)->
	fs.stat (path.join ROOT, requestLine["path"]), (err,stats)->
		if err
			callback null,404, createErrorHtml(404).length()
		else if AUTHORIZED_PATH.test(path.join ROOT,requestLine["path"])
			if stats.isDirectory()
				requestLine["path"] = path.join requestLine["path"],'/'
				callback 302,0
			else if stats.isFile()
				callback 200,stats["size"]
		else
			callback  relativePath,403, createErrorHtml(403).length()

parseRequestHeader = (data,callback)->
	requestLines = (data.toString().split "\r\n")
	# console.log '<<<<<<<<<< REQUEST >>>>>>>'
	# console.log data.toString() + '\n'
	firstLine =  requestLines.splice(0,1)[0]#0,1
	if FIRST_LINE_REGEX.test firstLine
		requestLine = {}
		requestLineArray = firstLine.split " "
		requestLine['method'] = requestLineArray[0]
		requestLine['protocol'] = requestLineArray[2]
		for line, index in requestLines
			if line.match REQUEST_HOST_REGEX
				regexLength = REQUEST_HOST_REGEX.toString().replace(/\//g,"").length
				requestLine[host] = line.substring regexLength, line.length
		requestLine['path'] = if requestLineArray[1].match REQUEST_PATH_REGEX then (path.join requestLineArray[1],"index.html") else requestLineArray[1]

		checkRequestPath (requestLine),(err, fileLength)->
			callback requestLine,err,fileLength
	else
		callback null,404,createErrorHtml(404)['Length']

createResponseHeader = (code, ext, fileLength,statusLine) ->

	responseHeader =
		statusLine : "#{DEFAULT_PROTOCOL} #{code} #{statusMessages[code]}"
		fields :
			'content-Type' : contentTypeMap[ext] ? 'text/plain'
			'Date' : new Date()
			'Content-Length' : fileLength ? 0
			'Connection' : 'close'
	if statusLine && (code is 302 || code is 301 )
		responseHeader.fields['Location'] = "http://" + (path.join statusLine['Host'],statusLine['path'])
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
			if statusCode is 302
				socket.end()
			else
				socket.end((createErrorHtml statusCode)['body'])

# Options for the server
ServerOptions =
	allowHalfOpen: false,
	pauseOnConnect: false

# SERVER
server = net.createServer ServerOptions, (socket)->

	socket.on 'data' ,(data)->
		parseRequestHeader data,(statusLine, statusCode, fileSize) ->
			extension = DEFAULT_EXTENSION
			if statusLine.path
				# console.log "\n<<<<<< statusLine >>>>>>>"
				# console.log statusLine
				if statusCode is 200
					extension = path.extname statusLine['path'].toLowerCase()
					readStream = fs.createReadStream (path.join ROOT,statusLine['path'])
					readStream.on 'end', ->
						socket.end()
					readStream.on 'error',(err)->
						socket.end()

			responseHeader = createResponseHeader statusCode, extension,fileSize,statusLine
			# console.log '\n<<<<<<<<<< RESPONSE >>>>>>>'
			# console.log responseHeader.toString()

				# Send the response (header + body)
			sendResponse socket, responseHeader, statusCode, readStream


	socket.on 'error',(err) ->
		console.log 'socket: error',err
	socket.on 'close', ->
		# console.log 'socket: close'

server.listen 9000,'localhost'

