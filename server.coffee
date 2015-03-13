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
	414 : "Request-URI Too Long"
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
class ErrorHtml
	constructor: (code) ->
		@body = "<!DOCTYPE html>
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
	getBody: ->
		@body
	length: ->
		Buffer.byteLength(@body, 'utf8')

# Determine statusCode contents' size and path that will be in the response Header

class RequestHeader
	constructor: (data) ->
		requestLine  = @parseRequestHeader data
		@method = requestLine.method
		@protocol = requestLine.protocol
		@path = requestLine.path
		@host = requestLine.Host
		@originalPath = requestLine.originalPath

	parseRequestHeader : (data)->
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
			requestLine['originalPath'] = match[2]
			requestLine['path'] = if match[2].match REQUEST_PATH_REGEX then (path.join match[2],"index.html") else match[2]

			return requestLine
		else
			null








class Response
	constructor :  ->

	getResponseInfo : (socket,requestLineData,callback)->
		# console.log '<<<<<<<<<<< requestLineData >>>>>>>>>'
		# console.log 'requestLineData',requestLineData
		fs.stat (path.join ROOT, requestLineData['path']), (err,stats)->
			tempExtension  = DEFAULT_EXTENSION
			tempPath = requestLineData['path']
			if requestLineData.method is 'GET' && Buffer.byteLength(path.basename(requestLineData.path), 'utf8') > 255
				tempPath = null
				tempStatusCode = 414
			else if err
				try
					err = fs.accessSync path.join(ROOT, requestLineData.originalPath), fs.R_OK
					tempPath = requestLineData.originalPath
					tempStatusCode = 403
					console.log err, tempStatusCode,tempPath
				catch error
					tempPath = null
					tempStatusCode = 404
					console.log error, tempStatusCode,tempPath
			else if AUTHORIZED_PATH.test(path.join ROOT,tempPath)
				if stats.isDirectory()
					tempPath = path.join tempPath,'/'
					tempStatusCode = 302
				else if stats.isFile()
					tempStatusCode = 200
					tempContentSize = stats['size']
					tempExtension = path.extname tempPath.toLowerCase()
			else
				tempStatusCode = 403

			if tempStatusCode isnt 200 && tempStatusCode isnt 302
				errorHtml = new ErrorHtml(tempStatusCode)
				tempErrorHtml= errorHtml.getBody()
				tempContentSize = errorHtml.length()
			tempReadStream = createReaderStream socket, tempPath,tempStatusCode
			tempHost = requestLineData.host ? null

			responseEntity =
				host : tempHost
				protocol : requestLineData.protocol
				extension : tempExtension
				referer : requestLineData.originalPath
				path : tempPath
				statusCode : tempStatusCode
				contentSize : tempContentSize
				readStream :tempReadStream
				errorHtml : tempErrorHtml
			# console.log '<<<<<<<<<<<<<< responseEntity >>>>>>>>>>>\n',responseEntity
			callback responseEntity

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


	createResponse : (socket,requestData,callback) ->
		@getResponseInfo socket, requestData, (responseEntity) =>
			@response =
				header : @createResponseHeader responseEntity
				body : @createResponseBody responseEntity
			callback()

	createResponseHeader :(responseInfo) ->
		responseHeader =
			statusLine : "#{responseInfo.protocol} #{responseInfo.statusCode} #{statusMessages[responseInfo.statusCode]}"
			fields :
				'content-Type' : contentTypeMap[responseInfo.extension] ? 'text/plain'
				'Date' : new Date()
				'Content-Length' : responseInfo.contentSize ? 0
				'Connection' : 'close'
		if (responseInfo.statusCode is 302 || responseInfo.statusCode is 301 )
			responseHeader.fields['Location'] = "http://" + (path.join responseInfo['host'],responseInfo['path'])
		toString = ->
			str = "#{responseHeader['statusLine']}\r\n"
			for i,v of responseHeader['fields']
				str += i + ': ' + v + "\r\n"
			str + '\r\n'

		{
			statusLine : responseHeader.statusLine
			fields : responseHeader.fields
			toString : toString
		}

	createResponseBody : (info) ->
		responseBody =
			errorHtml : info.errorHtml
			extension : info.extension
			readStream : info.readStream

	sendResponse :(socket) ->
		socket.write @response.header.toString(),=>
			if @response.body.readStream
				@response.body.readStream.pipe socket
			else
				if @response.header.statusCode is 302
					socket.end()
				else
					socket.end(@response.body.errorHtml)
	getResponse: ->
		@response



# Options for the server
ServerOptions =
	allowHalfOpen: false,
	pauseOnConnect: false

# SERVER
server = net.createServer ServerOptions, (socket)->

	socket.on 'data' ,(data)->
		requestHeader = new RequestHeader data
		# console.log '\n<<<<<<<<<< requestHeader >>>>>>>'
		# console.log requestHeader
		# console.log ''
		response = new Response(socket)

		response.createResponse socket, requestHeader,->
			# console.log '\n<<<<<<<<<< RESPONSE >>>>>>>'
			# console.log response.getResponse()
			response.sendResponse socket

	socket.on 'error',(err) ->
		console.log 'socket: error',err
	socket.on 'close', ->
		# console.log 'socket: close'

server.listen 9000,'localhost'

