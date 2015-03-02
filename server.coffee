fs = require 'fs'
net = require 'net'
path = require 'path'

root = __dirname + '/webroot'

options =
  allowHalfOpen: false,
  pauseOnConnect: false

statusCode =
	"200" : "OK"
	"201" : "Created"
	"202" : "Accepted"
	"204" : "No Content"
	"301" : "Moved Permanently"
	"302" : "Moved Temporarily"
	"304" : "Not Modified"
	"400" : "Bad Request"
	"401" : "Unauthorized"
	"403" : "Forbidden"
	"404" : "Not Found"
	"500" : "Internal Server Error"
	"501" : "Not Implemented"
	"502" : "Bad Gateway"
	"503" : "Service Unavailable"


contentTypeMap =
	'image' :
		tab : ["jpg","jpeg","png","bmp","gif"]

	'application' :
		tab : ['js']
		replace : ['javascript']
	'video' :
		tab : ['mp4']

	'audio' :
		tab : ['mp3']

	'text' :
		tab :['html','css']



REQUESTLINEREGEX = new RegExp "[GET|POST|HEAD][ ]([\/].*[ ]){0,1}HTTP\/1\.[0-9]"
PARENTDIRECTORYREGEX = new RegExp "[\.]{2,}[\/].*"


testHeader =
	"GET / HTTP/1.1"

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





FindContentTypeFile = (ext)->

	if !(ext is null)
		for i,tab of contentTypeMap
			index = tab['tab'].indexOf ext
			# console.log '>>>>>>>', i, tab, tab.indexOf ext
			if index >= 0
				return contentType =
					'type' : i
					'replace' : if tab['replace'] is undefined then ext else tab['replace']
		return options =
			'type' : 'text'
			'replace' : null

		return options =
			'type' : 'text'
			'replace' : null

# console.log contentTypeMap
# for i,tab of contentTypeMap
# 	console.log '>>>>>>>', i, tab


extractRequestLine = (data)->

	array = dataToArray data
	# console.log 'array', array
	requestLineArray = array[0]
	# console.log requestLineArray.toString()
	requestLineJSON =
		"method" : requestLineArray[0]
		"path" : requestLineArray[1] = if requestLineArray[1] == '/' || requestLineArray[1] == null || requestLineArray[1] == '' then 'index.html' else requestLineArray[1]
		"protocol" : requestLineArray[2]
	return requestLineJSON

isNotEmpty = (element)->

	return !(element is '')

dataToArray = (data)->

	array =  data.toString().split "\r\n"
	array = array.filter isNotEmpty	# console.log 'array',array
	for i in [0..array.length-1]
		array[i] = array[i].split " "
	return array

constructHeader = (protocole, ext, code, lengthFile) ->

	contentType = FindContentTypeFile ext
	# console.log 'contentType',
	contentSubType = if contentType['replace'] is null then 'plain' else contentType['replace']
	#  console.log 'contenType', contentType, ext
	contentLength = if lengthFile then "Content-Length:" + lengthFile+ "\r\n" else ""
	contentExt = if ext then "Content-Type:" + contentType['type'] + '/' + contentSubType + "\r\n" else "\r\n"
	protocole+ " " + code + " " +  statusCode[code] + "\r\n" + contentExt + contentLength + "Connection: close"+ "\r\n"+ "\r\n"

# replaceExtension = (options)->
# 	if options['type']#['replace'] is undefined
# 		console.log 'replace is undefined'

# arrayContains = (array, data)->
# 	for value in array
# 		if value is data
# 			return true
# 	false

# TEST

# console.log ["A", "B", "C"].indexOf("A")
# fileTest = "index.jpg"
# ext = path.extname fileTest
# ext = if ext.match (new RegExp ('[\.].*')) then ext.substring 1,ext.length else null
# console.log 'ext', ext



# console.log 'options', contentTypeFile ext


# string = "test/../index.html"
# console.log 'match', testHeader.match REQUESTLINEREGEX
# console.log 'search', testHeader.search REQUESTLINEREGEX
# console.log 'test', REQUESTLINEREGEX.test testHeader
# console.log 'exec', REQUESTLINEREGEX.exec testHeader

# console.log FindContentTypeFile 'mp3',

# requestLineHeaderJSON = extractRequestLine testHeader
# console.log 'firstLineHeaderJSON', requestLineHeaderJSON
# chemin = requestLineHeaderJSON['path']
# console.log 'path : ', chemin
# extension = (path.extname chemin.toLowerCase()).replace '.', ''
# contentType = FindContentTypeFile extension
# header = constructHeader requestLineHeaderJSON['protocol'],extension,"200"
# console.log 'headerResponse ', header

# console.log 'options', options = FindContentTypeFile 'js'



server = net.createServer (socket)->

	socket.on 'connection',connectionSocket = ->
		console.log 'socket : connection' + socket.remoteAddress +':'+ socket.remotePort + "\n"
	socket.on 'connect',connectSocket = ->
		console.log 'socket : connect'
	socket.on 'data' , dataSocket = (data)->
		requestLineHeaderJSON = extractRequestLine data
		chemin = requestLineHeaderJSON['path']
		# console.log 'chemin', chemin
		if !PARENTDIRECTORYREGEX.test chemin && REQUESTLINEREGEX.test chemin
			# console.log 'chemin.match',!PARENTDIRECTORYREGEX.test chemin
			filePath = path.join(root , chemin)
			# console.log 'filePath', filePath
			extension = (path.extname filePath.toLowerCase()).replace '.', ''
			# console.log 'search ', filePath, extension
			tempExtension = extension
			fs.stat filePath, (err,stats)->
				if err
					headerResponse = constructHeader requestLineHeaderJSON['protocol'],tempExtension, "404"
					console.log 'err',err
				else if stats.isFile()
					headerResponse = constructHeader requestLineHeaderJSON['protocol'],tempExtension, "200", stats["size"]
					readStream = fs.createReadStream(filePath)
				else
					headerResponse = constructHeader requestLineHeaderJSON['protocol'],tempExtension, "404"
				# console.log 'headerResponse',chemin,headerResponse
				socket.write headerResponse
				# console.log headerResponse
				readStream.on 'open', ->
					# console.log 'readStream ouvert'
					console.log requestLineHeaderJSON['method'].toUpperCase(),requestLineHeaderJSON['method'].toUpperCase() is 'GET' || requestLineHeaderJSON['method'].toUpperCase() is 'POST'
					if (requestLineHeaderJSON['method'].toUpperCase() is 'GET') || (requestLineHeaderJSON['method'].toUpperCase() is 'POST')
						readStream.pipe socket
					# readStream.close()
				readStream.on 'close', ->
					# console.log 'readStream close'

	socket.on 'error',errorSocket = ->
		# console.log 'socket : error'
	socket.on 'close',closeSocket = ->
		# console.log 'socket : close'

server.listen 9000,'patrice'
