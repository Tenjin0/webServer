### reference
	http://curl.haxx.se/rfc/cookie_spec.html
###

# MODULES RECQUIS
fs = require 'fs'
net = require 'net'
path = require 'path'

# CONSTANTES
conf = JSON.parse(fs.readFileSync(path.join(__dirname,'/conf/local.json')
	, 'utf8'))

DOMAIN_NAME = 'localhost'
SETCOOKIE = 'Set-Cookie'
ROOT = path.join( __dirname , conf.contentFolderPath)
sessionId = 1
DEFAULT_PROTOCOL = 'HTTP/1.0'
DEFAULT_EXTENSION = '.html'
SESSION_ID = "sessionId"


# REGEXS
FIRST_LINE_REGEX = new RegExp "^(GET|POST|HEAD) ([\/].*) (HTTP\/[01]\.[0-9])$"
AUTHORIZED_PATH = new RegExp "#{ROOT}.*"
host = "Host"
REQUEST_HOST_REGEX = new RegExp "#{host}: ((.*):([]|[0-9]{4}))"
REQUEST_PATH_REGEX = new RegExp "#{"\/$"}"
COOKIE_REGEX = new RegExp "Cookie: (([^;]*=[^;]*;)*[^;]*=[^;]*)$"
NAME_VALUE_REGEX = new RegExp "(.*)=(.*)"


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
	# ErrorHtml.toto = 'totos'
	# getToto : ->
	# 	ErrorHtml.toto
	getBody: ->
		@body
	length: ->
		Buffer.byteLength(@body, 'utf8')


# Determine statusCode contents' size and path that will be in the response Header

class RequestHeader
	constructor: (socket,data) ->
		requestLine  = @parseRequestHeader socket,data
		if requestLine
			@method = requestLine.method
			@protocol = requestLine.protocol
			@path = requestLine.path
			@host = requestLine.host ? null
			@originalPath = requestLine.originalPath
			@cookies = @transformCookies requestLine.cookies
		else
			throw new Error 'RequestHeader not create'

	parseRequestHeader : (socket,data)->
		# console.log '<<<<<<<<<< REQUEST DATA >>>>>>>'
		# console.log data.toString() + '\n'
		requestLines = (data.toString().split "\r\n")
		# console.log '<<<<<<<<<< REQUEST LINES >>>>>>>'
		# console.log requestLines + '\n'
		firstLine =  requestLines.splice(0,1)[0]#0,1
		firstLine.match FIRST_LINE_REGEX
		if match = firstLine.match FIRST_LINE_REGEX
			requestLine = {}
			requestLine['method'] = match[1]
			requestLine['protocol'] = match[3]
			for line, index in requestLines
				if matchHost = line.match REQUEST_HOST_REGEX
					requestLine.host =
						domain : matchHost[2]
						port : matchHost[3]
				else
					requestLine.host =
						domain : socket.remoteAddress
						port : socket.localPort
				# console.log requesstLine.host
				if matchCookie = line.match COOKIE_REGEX
					requestLine['cookies'] =[]
					split = matchCookie[1].split("; ")
					for i in split
						match2 = i.match NAME_VALUE_REGEX
						requestLine.cookies[match2[1]] = match2[2]
			requestLine['originalPath'] = match[2]
			requestLine['path'] = if match[2].match REQUEST_PATH_REGEX then (path.join match[2],"index.html") else match[2]

			return requestLine
		else
			null

	transformCookies : (cookiesArray)->
		cookies = []
		for i,v of cookiesArray
			cookies.push (new Cookie(i,v))
		cookies

	getCookies : ->
		@cookies

	getCookieSession : ->
		for i,v of @cookies
			if i is SESSION_ID
				return new Cookie(i,v)
		return null

	getDomain: ->
		if @host
			@host.domain
		else
			null

class Cookie
	constructor : (name,value,domain)->
		# console.log name,value,domain
		@name = name
		@value = value
		@fields =
			date : null
			domain : null
			path : null
		if domain
			@fields['domain'] = null
		@fields['path'] = "/"
		@fields['date'] = null


	setDomain : (domain)->
		@domain = domain

	setPath : (path)->
		@path = path


	# SETCOOKIE: NAME=VALUE; expires=DATE;
	# path=PATH; domain=DOMAIN_NAME; secure
	toString : ->
		str = "#{@name}=#{@value}"
		for i, v of @fields
			# console.log i,v
			str += if v then "; #{i}=#{v}" else ""
		str += if @secure then "; secure" else ""



class SessionCookie extends Cookie
	constructor : (domain)->
		super SESSION_ID,sessionId++,domain
		# @domain = domain


class Response
	constructor :  ->
		@response =
			header :
				fields :
					SETCOOKIE : []
			body : null

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
					# console.log err, tempStatusCode,tempPath
				catch error
					tempPath = null
					tempStatusCode = 404
					# console.log error, tempStatusCode,tempPath
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
			# tempHost = requestLineData.host ? null

			responseEntity =
				method : requestLineData.method
				host : requestLineData.host
				protocol : requestLineData.protocol
				extension : tempExtension
				referer : requestLineData.originalPath
				path : tempPath
				statusCode : tempStatusCode
				contentSize : tempContentSize
				readStream :tempReadStream
				errorHtml : tempErrorHtml
			# console.log '\n<<<<<<<<<<<<<< responseEntity >>>>>>>>>>>\n',responseEntity
			callback responseEntity

	addCookies : (cookies) ->
		# for i,value of cookies
		# 	console.log  '>>>>>>>>>>> ',i,value.name
		@response.header.fields[SETCOOKIE] =
		@response.header.fields[SETCOOKIE].concat cookies

	addCookie : (cookie)->
		# console.log 'response: cookies',@response.header
		@response.header.fields[SETCOOKIE].push cookie

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
				'Content-Type' : contentTypeMap[responseInfo.extension] ? 'text/plain'
				'Date' : new Date()
				'Content-Length' : if (responseInfo.contentSize && responseInfo.method  isnt 'HEAD') then responseInfo.contentSize else 0
				'Connection' : 'close'
				'Set-Cookie' : []
		if (responseInfo.statusCode is 302 || responseInfo.statusCode is 301 )
			responseHeader.fields['Location'] = "http://" + (path.join "#{responseInfo.host.domain}:#{responseInfo.host.port}",responseInfo['path'])

		toString = ->
			str = "#{responseHeader['statusLine']}\r\n"
			for i,v of responseHeader['fields']
				if i is SETCOOKIE
					# str += "#{i}: "
					for ind,val of v
						str += "#{i}: #{val.name}=#{val.value}; path=#{val.fields.path}\r\n"
						# else
							# str += "path=#{val.fields.path}"
					# str += "\r\n"
				else
					str += i + ': ' + v + "\r\n"
			str + '\r\n'

		{
			statusLine : responseHeader.statusLine
			fields : responseHeader.fields
			toString : toString
		}

	createResponseBody : (info) ->
		responseBody =
			extension : info.extension

		if info.method is 'GET' || info.method is 'POST'
			responseBody['readStream'] =info.readStream
			responseBody['errorHtml'] = info.errorHtml
		else
			responseBody['readStream'] = null
			responseBody['errorHtml'] = null
		responseBody

	sendResponse :(socket) ->
		socket.write @response.header.toString(),=>
			if @response.body.readStream
				@response.body.readStream.pipe socket
			else
				if @response.header.statusCode is 302 || !@response.body.errorHtml
					socket.end()
				else
					socket.write(@response.body.errorHtml)
	getResponse: ->
		@response

	getCookies : ->
		@response.header.fields[SETCOOKIE]


# EXPORTS

module.exports =

	DEFAULT_PROTOCOL : DEFAULT_PROTOCOL
	DEFAULT_EXTENSION : DEFAULT_EXTENSION
	DOMAIN_NAME : DOMAIN_NAME
	ROOT : ROOT
	SESSION_ID : SESSION_ID
	SETCOOKIE : SETCOOKIE

	# REGEXS
	AUTHORIZED_PATH: AUTHORIZED_PATH
	FIRST_LINE_REGEX : FIRST_LINE_REGEX
	NAME_VALUE_REGEX : NAME_VALUE_REGEX
	REQUEST_HOST_REGEX : REQUEST_HOST_REGEX
	REQUEST_PATH_REGEX : REQUEST_PATH_REGEX

	#ARRAYS
	contentTypeMap :  contentTypeMap
	statusMessages :  statusMessages

	# CLASSES
	Cookie : Cookie
	ErrorHtml : ErrorHtml
	RequestHeader : RequestHeader
	Response : Response
	SessionCookie : SessionCookie
