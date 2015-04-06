### reference
	cookie spec : http://curl.haxx.se/rfc/cookie_spec.html
	buffer https://docs.nodejitsu.com/articles/advanced/buffers/how-to-use-buffers
###

# MODULES RECQUIS

fs = require 'fs'
net = require 'net'
path = require 'path'

uploadClass = require './class'

DOMAIN_NAME =  uploadClass.DOMAIN_NAME
ROOT =  uploadClass.ROOT
DEFAULT_PROTOCOL = uploadClass.DEFAULT_PROTOCOL
DEFAULT_EXTENSION =  uploadClass.DEFAULT_EXTENSION
SESSION_ID =  uploadClass.SESSION_ID

# REGEXS
FIRST_LINE_REGEX = uploadClass.FIRST_LINE_REGEX
AUTHORIZED_PATH = uploadClass.AUTHORIZED_PATH
REQUEST_HOST_REGEX = uploadClass.REQUEST_HOST_REGEX
REQUEST_PATH_REGEX = uploadClass.REQUEST_PATH_REGEX
NAME_VALUE_REGEX = uploadClass.NAME_VALUE_REGEX

#ARRAYS
statusMessages = uploadClass.statusMessages
contentTypeMap = uploadClass.contentTypeMap

# CLASSES
ErrorHtml = uploadClass.ErrorHtml
RequestHeader = uploadClass.RequestHeader
Cookie = uploadClass.Cookie
SessionCookie = uploadClass.SessionCookie
Response = uploadClass.Response



# Options for the server
ServerOptions =
	allowHalfOpen: true,
	pauseOnConnect: true

# SERVER
server = net.createServer ServerOptions, (socket)->
	server.getConnections (err,count) ->
		console.log 'server connections',err, count,socket.remoteAddress,socket.remotePort,socket.remoteFamily
	socket.setEncoding('utf8')
	socket.resume()
	socket.on 'data' ,(data)->
		if !tempData
			tempData = new Buffer(data,"utf-8")

		tempData.write data,"utf-8"
		# console.log '\n<<<<<<<<<< DATA >>>>>>>'
		# console.log tempData
		if match = data.toString().match new RegExp "\r\n\r\n"
			socket.pause()
			#console.log 'ca marche',data.substring 0,match.index
		# console.log '\n<<<<<<<<<< Request >>>>>>>'
		# console.log data.toString('utf-8')
			try
				requestHeader = new RequestHeader socket,data.substring 0,match.index
				response = new Response()
				response.createResponse socket, requestHeader,->

					if !(sessionCookie =requestHeader.getCookieSession())
						sessionCookie = new SessionCookie(requestHeader.getDomain())
						response.addCookie(sessionCookie)

						# console.log '\n<<<<<<<<<< ResponseCookies >>>>>>>'
						# console.log response.getCookies()

						# cookies = []
						# c = new Cookie('name','toto')
						# d = new Cookie('lastName','titi')
						# cookies.push c
						# cookies.push d
						# response.addCookies cookies
						# console.log  cookies

						# console.log '\n<<<<<<<<<< ResponseCookies >>>>>>>'
						# console.log response.getCookies()
						# response.addCookies(requestHeader.getCookies())

						# console.log '\n<<<<<<<<<< RESPONSE >>>>>>>'
						# console.log response.getResponse()
						# socket.pause()
						response.sendResponse socket
						# socket.resume()
			catch err
				console.log 'error',err
				#socket.destroy()
				socket.resume()
			finally
				socket.resume()
	socket.on 'error',(err) ->
		console.log 'socket: error',err
		socket.destroy()
		socket.on 'open', ->
		console.log 'socket: open',socket.remoteAddress,socket.remotePort
	socket.on 'close', ->
		console.log 'socket: close'
	socket.setTimeout 10000
	socket.on 'timeout', ->
		console.log 'socket: timeout...'
		socket.destroy()

	server.on 'error', (err) ->
		console.log 'server: error',err

server.listen 9000,DOMAIN_NAME

