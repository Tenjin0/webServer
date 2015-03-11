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
FIRST_LINE_REGEX = new RegExp "^(GET|POST|HEAD) ([\/].*) (HTTP\/[01]\.[0-9])$"
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
# Determine statusCode contents' size and path that will be in the response Header
#prepareresponseAttributes
createResponse = (socket,requestLineData,callback)->
	fs.stat (path.join ROOT, requestLineData['path']), (err,stats)->
		responseEntity =
			 path : requestLineData['path']
		responseAttributes =
			extension : DEFAULT_EXTENSION
		if err
			responseEntity['path'] = null
			responseAttributes['status'] = 404
			responseEntity['size '] = createErrorHtml(responseAttributes['statusCode']).length()
		else if AUTHORIZED_PATH.test(path.join ROOT,responseEntity["path"])
			if stats.isDirectory()
				responseEntity['path'] = path.join responseEntity["path"],'/'
				responseAttributes['statusCode'] = 302
			else if stats.isFile()
				responseAttributes['statusCode'] = 200
				responseEntity['size'] = stats['size']
				responseAttributes['extension'] = path.extname responseEntity['path'].toLowerCase()
		else
			responseAttributes['statusCode'] = 403

		if responseAttributes['statusCode'] isnt 200 && responseAttributes['statusCode'] isnt 302
			errorHtml = createErrorHtml(responseAttributes['statusCode'])
			responseEntity['errorHtml'] = errorHtml.body
			responseEntity['size'] = errorHtml.length()
		responseEntity['readStream'] = createReaderStream socket, responseEntity['path'],responseAttributes['statusCode']

		responseHeader = createResponseHeader responseAttributes, requestLineData, responseEntity

		callback responseHeader , responseEntity




parseRequestHeader = (data,callback)->
	requestLines = (data.toString().split "\r\n")
	# console.log '<<<<<<<<<< REQUEST >>>>>>>'
	# console.log data.toString() + '\n'
	firstLine =  requestLines.splice(0,1)[0]#0,1
	firstLine.match FIRST_LINE_REGEX
	if match = firstLine.match FIRST_LINE_REGEX
		requestLine = {}
		requestLine['method'] = match[1]
		requestLine['protocol'] = match[3]
		for line, index in requestLines
			if line.match REQUEST_HOST_REGEX
				regexLength = REQUEST_HOST_REGEX.toString().replace(/\//g,"").length
				requestLine[host] = line.substring regexLength, line.length

		requestLine['path'] = if match[2].match REQUEST_PATH_REGEX then (path.join match[2],"index.html") else match[2]
		return requestLine

	else
		null

createResponseHeader = (responseAttributes,request, responseEntity) ->
	responseHeader =
		statusLine : "#{request.protocol} #{responseAttributes.statusCode} #{statusMessages[responseAttributes.statusCode]}"
		fields :
			'content-Type' : contentTypeMap[responseAttributes.extension] ? 'text/plain'
			'Date' : new Date()
			'Content-Length' : responseEntity.size ? 0
			'Connection' : 'close'
	if request && (responseAttributes.statusCode is 302 || responseAttributes.statusCode is 301 )
		responseHeader.fields['Location'] = "http://" + (path.join request['Host'],responseEntity['path'])
	toString : ->
		str = "#{responseHeader['statusLine']}\r\n"
		for i,v of responseHeader['fields']
			str += i + ': ' + v + "\r\n"
		str + '\r\n'



createReaderStream = (socket,relativePath,statusCode)->
	if statusCode is 200
		readStream = fs.createReadStream(path.join ROOT,relativePath)
		readStream.on 'end', ->
			socket.end()
		readStream.on 'error',(err)->
			socket.end()
		return readStream
	else
		null

sendResponse = (socket, header, body) ->
	console.log body.path,'\n',header.toString()
	socket.write header.toString(),->
		if body.readStream
			body.readStream.pipe socket
		else
			if header.statusCode is 302
				socket.end()
			else
				socket.end(body.errorHtml)
# Options for the server
ServerOptions =
	allowHalfOpen: false,
	pauseOnConnect: false

# SERVER
server = net.createServer ServerOptions, (socket)->

	socket.on 'data' ,(data)->
		requestHeader = parseRequestHeader data

		createResponse socket, requestHeader,(responseHeader,responseEntity)->
			# console.log '\n<<<<<<<<<< RESPONSE >>>>>>>'
			# console.log responseHeader.toString()
			sendResponse socket, responseHeader, responseEntity

	socket.on 'error',(err) ->
		console.log 'socket: error',err
	socket.on 'close', ->
		# console.log 'socket: close'

server.listen 9000,'localhost'

