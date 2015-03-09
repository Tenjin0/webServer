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
	length : Buffer.byteLength(@body, 'utf8')

createAbsolutePath = (relativePath,callback)->
	fs.stat (path.join ROOT,relativePath), (err,stats)->
		if err
			# console.log err,createErrorHtml(404)
			callback null,404, createErrorHtml(404)['Length']
		else if AUTHORIZED_PATH.test(path.join ROOT,relativePath)
			if stats.isDirectory() #|| !AUTHORIZED_PATH.test(path.join ROOT,relativePath)
				fs.stat (path.join ROOT, relativePath, 'index.html'), (err, stats2)-> 
					# console.log !AUTHORIZED_PATH.test(path.join ROOT, relativePath, 'index.html')
					if err
						callback (path.join ROOT, relativePath),403, createErrorHtml(403)['Length']
					else
						callback (path.join ROOT, relativePath, 'index.html'),200,stats2["size"]
			else
				callback (path.join ROOT,relativePath),200,stats["size"]
		else
			callback (path.join ROOT, relativePath),403, createErrorHtml(403)['Length']
	# try
	# 	stats = fs.statSync path.join ROOT,relativePath	
	# 	if stats.isDirectory() && fs.existsSync (path.join ROOT, relativePath, 'index.html')
	# 		temp = path.join ROOT, relativePath, 'index.html'
	# 	else
	# 		temp = path.join ROOT, relativePathac
	# 	console.log relativePath, temp
	# catch error 
	# 	temp = path.join ROOT, relativePath
	# temp

isNotEmpty = (element)-> 
	element isnt ""

# fruits = ["Banana", "Orange", "Apple", "Mango"]

# console.log(fruits)
# console.log("Removed: " + fruits.splice(0,1))
# console.log(fruits)

parseStatusLine = (data,callback)->
	RequestLines = (data.toString().split "\r\n")
	console.log '<<<<<<<<<< REQUEST >>>>>>>'
	console.log data.toString()
	firstLine =  RequestLines.splice(0,1)[0]#0,1
	# console.log "RequestLines.splice 0, 1", RequestLines[0],  
	if FIRST_LINE_REGEX.test firstLine
		requestLineArray = firstLine.split " "
		requestLine = {}
		for line, index in RequestLines
			# console.log  line.match REQUEST_HOST_REGEX
			if line.match REQUEST_HOST_REGEX
				# console.log 'line',line
				regexLength = REQUEST_HOST_REGEX.toString().replace(/\//g,"").length
				requestLine[host] = line.substring regexLength, line.length
			if line.match REQUEST_REF_REGEX
				# console.log 'line',line
				regexLength = REQUEST_REF_REGEX.toString().replace(/\//g,"").length
				requestLine[referer] = line.substring regexLength, line.length

		regex = new RegExp requestLine[host]
		# console.log requestLine 
		if requestLine[referer]
			console.log (requestLine[referer].match regex)
			subdirectory = requestLine[referer].substring ((requestLine[referer].match regex).index + requestLine[host].length), requestLine[referer].length
		else
			subdirectory = "/"
		# console.log (path.join subdirectory, requestLineArray[1])
		createAbsolutePath (path.join subdirectory, requestLineArray[1]),(path, err, fileLength)->
			if path
				
					# console.log index,line	
				requestLine['method'] =  requestLineArray[0] # firstLine.substring 0,indexOf(' ')
				requestLine['path'] = path
				requestLine['protocol'] = requestLineArray[2]
				
				# console.log '\n<<<<<<<<<< requestLine  >>>>>>>>>'
				# console.log requestLine
				callback requestLine,err,fileLength
			else
				callback null,err,fileLength

	else
		# console.log 404 , createErrorHtml(404)['Length']
		callback null,404,createErrorHtml(404)['Length']


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
		parseStatusLine data,(statusLine, statusCode, fileSize) ->
			extension = DEFAULT_EXTENSION
			if statusLine
				# console.log "<<<<<< statusLine >>>>>>>"
				# console.log "statusLine", statusLine
				# extension = path.extname statusLine['path'].toLowerCase()
				# fs.stat statusLine['path'], (err,stats)->
				# if err
				# 	statusCode = 404
				# else if stats.isDirectory() || !AUTHORIZED_PATH.test statusLine['path']
				# 	statusCode = 403
				if statusCode is 200
				# else if stats.isFile()
				# 	statusCode = 200
					extension = path.extname statusLine['path'].toLowerCase()
					readStream = fs.createReadStream statusLine['path']
					readStream.on 'end', ->
						socket.end()

				# Create responseHeader
			responseHeader = createResponseHeader statusCode, extension,fileSize
			# console.log statusLine['path']
			# console.log '<<<<<<<<<< RESPONSE >>>>>>>'
			# console.log responseHeader.toString()
				# Send the response (header + body)
			sendResponse socket, responseHeader, statusCode, readStream
			# else
			# 	responseHeader = createResponseHeader statusCode
			# 	sendResponse socket, responseHeader, statusCode

	socket.on 'error',(err) ->
		console.log 'socket: error',err
	# socket.on 'close', ->
	# 	console.log 'socket: close'

server.listen 9000,'localhost'
