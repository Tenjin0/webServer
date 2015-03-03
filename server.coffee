fs = require 'fs'
net = require 'net'
path = require 'path'

root = __dirname + '/webroot'

options =
  allowHalfOpen: false,
  pauseOnConnect: false

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

simpleHeader =
	"GET / HTTP/1.0"

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
	# console.log 'toto'
	for ext in tab['tab']
		subType = if tab['replace'] is undefined then ext.replace('.', '') else tab['replace']
		# console.log ext, newContentTypeMap[ext] = "#{type}/#{subType}"
		newContentTypeMap.push (newContentTypeMap[ext] = "#{type}/#{subType}")


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

FIRST_LINE_REGEX = new RegExp "(GET|POST|HEAD)[ ]([\/].*[ ]){1,}HTTP\/1\.[0-9]"
PARENT_DIRECTORY_REGEX = new RegExp "[\.]{2,}[\/].*"
METHOD_REGEX  = new RegExp "(GET|POST|HEAD)"
DEFAULT_PROTOCOL = 'HTTP/1.0'
DEFAULT_EXTENSION = '.html'

# for i,tab of contentTypeMap
# 	console.log '>>>>>>>', i, tab


extractRequestLine = (data)->

	firstLine =  (data.toString().split "\r\n")[0]
	# console.log 'firstLine',firstLine
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
	# protocole + ' ' + code + ' ' + statusCode[code]
	date : null
	server : null
	contentType : "Content-Type: "  + if ext && !(newContentTypeMap[ext] is undefined) then "#{newContentTypeMap[ext]}\r\n" else "text/plain\r\n"
	contentLength : if lengthFile then "Content-Length: #{lengthFile}\r\n" else "Content-Length: 0\r\n"
	expires : null
	lastModified : null
	connection : "Connection: close\r\n"

	toString :->
		"#{@statusLine}#{@contentType}#{@contentLength}#{@connection}\r\n"



# DONNEE DE TEST
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

# TEST

# console.log newContentTypeMap
# requestLineHeader = extractRequestLine httpRequest
# console.log requestLineHeader
# if requestLineHeader
# 	absolutePath = path.join(root , requestLineHeader['path'])
# 	tempExtension = (path.extname absolutePath.toLowerCase()).replace '.', ''
	# tempExtension = if tempExtension is '' then null else tempExtension
# 	if extension is ''
# 		console.log 'extension est une chaine vide xD'
# 	else
# 		console.log requestLineHeader['path'], 'extension', extension
# 	stats = fs.statSync absolutePath
# 	console.log stats.isDirectory()
# 	header = createResponseHeader requestLineHeader['protocol'],403,extension
# 	console.log  header
# else
# 	header = createResponseHeader DEFAULT_PROTOCOL,400
# console.log '<< headerResponse >>\n' +  header.toString()
# console.log (errorHtml 400).toString()
# string = "GET /images HTTP/1.0"
# console.log 'match', string.match FIRST_LINE_REGEX
# console.log 'search', string.search FIRST_LINE_REGEX
# console.log 'test', FIRST_LINE_REGEX.test string
# console.log 'exec', FIRST_LINE_REGEX.exec string

# console.log newContentTypeMap['.map']

# for index, value of newContentTypeMap
# 	(stat = ->
# 		console.log index,value
# 	)()
server = net.createServer options, (socket)->

	socket.on 'connection',connectionSocket = ->

		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort + "\n"
	socket.on 'connect',connectSocket = ->

		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->

		requestLineHeader = extractRequestLine data
		console.log  'data', data
		console.log 'requestLineHeader', requestLineHeader
		if requestLineHeader #&& !PARENT_DIRECTORY_REGEX.test requestLineHeader['path']
			absolutePath = path.join(root , requestLineHeader['path'])
			extension = (path.extname absolutePath.toLowerCase())
			fs.stat absolutePath, (err,stats)->
				codeError = null
				tempStats = stats
				taille = null
				if err
					codeError = 404
				else if PARENT_DIRECTORY_REGEX.test requestLineHeader['path']
					codeError = 403
				else if stats.isFile()
					headerResponse = createResponseHeader requestLineHeader['protocol'], 200,extension, tempStats["size"]
					readStream = fs.createReadStream(absolutePath)
					# socket.write headerResponse.toString()
				else if stats.isDirectory()
					codeError = 403

				if codeError
					headerResponse = createResponseHeader requestLineHeader['protocol'], codeError, DEFAULT_EXTENSION,Buffer.byteLength((errorHtml codeError).toString(), 'utf8')
					socket.write headerResponse.toString(),->
						socket.write (errorHtml codeError).toString() + '\n'
				console.log '>>>>> \n'
				console.log '\n',requestLineHeader['path'], 'extension', extension
				console.log headerResponse.toString()
				if readStream
					readStream.on 'open', ->
						if (requestLineHeader['method'].toUpperCase() is 'GET') || (requestLineHeader['method'].toUpperCase() is 'POST')
							socket.write headerResponse.toString(),->
								readStream.pipe socket
						# else
						# 	socket.end()
					readStream.on 'close', ->
						console.log 'readStream close'

		else
			headerResponse = createResponseHeader DEFAULT_PROTOCOL, 400
			console.log 'headerResponse error', headerResponse.toString()
			# console.log errorHtml 400
			# socket.write (errorHtml 400).toString() + '\n'
			socket.write headerResponse.toString()



	socket.on 'error',errorSocket = ->
		# console.log 'socket : error'
	socket.on 'close',closeSocket = ->
		# console.log 'socket : close'

server.listen 9000,'localhost'
