# MODULES RECQUIS
fs = require 'fs'
net = require 'net'
path = require 'path'

# CONSTANTTE
ROOT = __dirname + '/webroot'
DEFAULT_PROTOCOL = 'HTTP/1.0'
DEFAULT_EXTENSION = '.html'

# REGEX
FIRST_LINE_REGEX = new RegExp "(GET|POST|HEAD)[ ]([\/].*[ ]){1,}HTTP\/1\.[0-9]"
PARENT_DIRECTORY_REGEX = new RegExp "[\.]{2,}[\/].*"
METHOD_REGEX  = new RegExp "(GET|POST|HEAD)"


# DATA
statusCode =
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
	'image' :
		tab : [".jpg",".jpeg",".png",".bmp",".gif"]

	'application' :
		tab : ['.js']
		replace : ['javascript']
	'video' :
		tab : ['.mp4']

	'audio' :
		tab : ['.mp3']

	'text' :
		tab :['.html','.css']


# transform contentTypeMap in a more simple array ext -> contentType
newContentTypeMap = []
for type,tab of contentTypeMap
	for ext in tab['tab']
		subType = if tab['replace'] is undefined then ext.replace('.', '') else tab['replace']
		newContentTypeMap.push (newContentTypeMap[ext] = "#{type}/#{subType}")


# OBJET AND FUNCTION
errorHtml = (code) ->
	body : "<!DOCTYPE html>
<html>
<head>
	<title>Webserver Test</title>
	<meta charset='utf-8'>
</head>
<body>
	<H2>#{code} #{statusCode[code]}</H2>
</body>
</html>
"
	toString : ->
		return @body.toString()


extractStatusLine = (data)->

	firstLine =  (data.toString().split "\r\n")[0]
	if FIRST_LINE_REGEX.test firstLine
		requestLineArray = firstLine.split " "
		requestLineJSON =
			"method" : requestLineArray[0] # firstLine.substring 0,indexOf(' ')
			"path" : if requestLineArray[1] == '/' then 'index.html' else requestLineArray[1]
			"protocol" : requestLineArray[2]
		return requestLineJSON
	return null

createResponseHeader = (protocole, code, ext, lengthFile) ->
	statusLine  : "#{protocole} #{code} #{statusCode[code]}\r\n"
	date : null
	server : null
	contentType : "Content-Type: "  + if ext && newContentTypeMap[ext] then "#{newContentTypeMap[ext]}\r\n" else "text/plain\r\n"
	contentLength : if lengthFile then "Content-Length: #{lengthFile}\r\n" else "Content-Length: 0\r\n"
	expires : null
	lastModified : null
	connection : "Connection: close\r\n"

	toString :->
		"#{@statusLine}#{@date}#{@contentType}#{@contentLength}#{@connection}\r\n"


ServerOptions =
  allowHalfOpen: false,
  pauseOnConnect: false


#SERVER
server = net.createServer ServerOptions, (socket)->

	socket.on 'connection', ->

		console.log 'socket : connect'
	socket.on 'data' ,(data)->

		requestLineHeader = extractStatusLine data
		console.log requestLineHeader
		if requestLineHeader #&& !PARENT_DIRECTORY_REGEX.test requestLineHeader['path']
			absolutePath = path.join(ROOT , requestLineHeader['path'])
			extension = (path.extname absolutePath.toLowerCase())
			fs.stat absolutePath, (err,stats)->
				codeError = null
				if err
					codeError = 404
				else if PARENT_DIRECTORY_REGEX.test requestLineHeader['path'] || stats.isDirectory()
					codeError = 403
				else if stats.isFile()
					headerResponse = createResponseHeader requestLineHeader['protocol'], 200,extension, stats["size"]
					readStream = fs.createReadStream absolutePath
				# else if stats.isDirectory()
				# 	codeError = 403

				if codeError
					headerResponse = createResponseHeader requestLineHeader['protocol'], codeError, DEFAULT_EXTENSION,Buffer.byteLength((errorHtml codeError).toString(), 'utf8')
					socket.write headerResponse.toString(),->
						socket.write (errorHtml codeError).toString() + '\n'

				if readStream # ASYNCHRONOUS CALL
					readStream.on 'open', ->
						if (requestLineHeader['method'].toUpperCase() is 'GET') || (requestLineHeader['method'].toUpperCase() is 'POST')
							socket.write headerResponse.toString(),->
								readStream.pipe socket

		else
			headerResponse = createResponseHeader DEFAULT_PROTOCOL, 400
			# console.log 'headerResponse error', headerResponse.toString()
			socket.write headerResponse.toString()

	# socket.on 'error', ->
	# 	console.log 'socket : error'
	# socket.on 'close', ->
	# 	console.log 'socket : close'

server.listen 9000,'localhost'
