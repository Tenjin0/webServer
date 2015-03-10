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
host = "Host"
referer = "Referer"
REQUEST_HOST_REGEX = new RegExp "#{host}: "
REQUEST_REF_REGEX = new RegExp "#{referer}: "
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

checkRequestPath = (relativePath,callback)->
	fs.stat (path.join ROOT, relativePath), (err,stats)->
		console.log 'relativePath', relativePath ,'absolutePath', (path.join ROOT, relativePath)
		if err
			console.log 'stat err', err.path,createErrorHtml(404).length()
			callback null,404, createErrorHtml(404).length()
		else if AUTHORIZED_PATH.test(path.join ROOT,relativePath)
			if stats.isFile()
				callback relativePath,200,stats["size"]
			else
				callback (path.join relativePath,'/'),302,0
		else
			callback  relativePath,403, createErrorHtml(403).length()

parseREquestHeader = (data,callback)->
	requestLines = (data.toString().split "\r\n")
	console.log '<<<<<<<<<< REQUEST >>>>>>>'
	console.log data.toString() + '\n'
	firstLine =  requestLines.splice(0,1)[0]#0,1
	if FIRST_LINE_REGEX.test firstLine
		requestLineArray = firstLine.split " "
		requestLine = {}
		for line, index in requestLines
			if line.match REQUEST_HOST_REGEX
				regexLength = REQUEST_HOST_REGEX.toString().replace(/\//g,"").length
				requestLine[host] = line.substring regexLength, line.length
		requestLineArray[1] = if requestLineArray[1].match REQUEST_PATH_REGEX then (path.join requestLineArray[1],"index.html") else requestLineArray[1]
		console.log "requestLineArray[1]", requestLineArray[1]
		checkRequestPath (requestLineArray[1]),(relativePath, err, fileLength)->
			# console.log 'callback createAbsolutePath',relativePath, err, fileLength
			if relativePath
				requestLine['method'] =  requestLineArray[0] # firstLine.substring 0,indexOf(' ')
				requestLine['path'] = relativePath
				requestLine['protocol'] = requestLineArray[2]

				callback requestLine,err,fileLength
			else
				callback null,err,fileLength

	else
		# console.log 404 , createErrorHtml(404)['Length']
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
		console.log statusLine['Host'],statusLine['path']
		responseHeader.fields['Location'] = "http://" + (path.join statusLine['Host'],statusLine['path'])
	# console.log  'responseHeader', responseHeader
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
		parseREquestHeader data,(statusLine, statusCode, fileSize) ->
			extension = DEFAULT_EXTENSION
			if statusLine
				console.log "\n<<<<<< statusLine >>>>>>>"
				console.log statusLine

				# console.log originePath
				# if statusLine['origin']
				if statusCode is 200
				# else if stats.isFile()
				# 	statusCode = 200
					extension = path.extname statusLine['path'].toLowerCase()
					# console.log path.join ROOT,statusLine['path']
					readStream = fs.createReadStream (path.join ROOT,statusLine['path'])
					readStream.on 'end', ->
						socket.end()
					readStream.on 'error',(err)->
						console.log 'readStream.on err:',err
						socket.end()

				# Create responseHeader
			responseHeader = createResponseHeader statusCode, extension,fileSize,statusLine
			console.log '\n<<<<<<<<<< RESPONSE >>>>>>>'
			console.log responseHeader.toString()

				# Send the response (header + body)
			sendResponse socket, responseHeader, statusCode, readStream
			# else
			# 	responseHeader = createResponseHeader statusCode
			# 	sendResponse socket, responseHeader, statusCode

	socket.on 'error',(err) ->
		console.log 'socket: error',err
	socket.on 'close', ->
		console.log 'socket: close'

server.listen 9000,'localhost'

