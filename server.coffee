### reference
	http://curl.haxx.se/rfc/cookie_spec.html
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
	pauseOnConnect: false

# SERVER
server = net.createServer ServerOptions, (socket)->
	server.getConnections (err,count) ->
		console.log 'server connections',err, count
	socket.setEncoding('utf8')
	socket.on 'data' ,(data)->
		if !tempData
			tempData = ""
		tempData += data
		console.log '\n<<<<<<<<<< DATA >>>>>>>'
		console.log tempData
		if match = tempData.match new RegExp ".*"
			# console.log 'ca marche',match
		# console.log '\n<<<<<<<<<< Request >>>>>>>'
		# console.log data.toString('utf-8')
		# console.log ''
			try
				requestHeader = new RequestHeader data
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
					response.sendResponse socket

			catch err
				console.log 'error',err
				socket.destroy()
	socket.on 'error',(err) ->
		console.log 'socket: error',err
		socket.destroy()
	socket.on 'close', ->
		console.log 'socket: close'
	socket.setTimeout 30000
	socket.on 'timeout', ->
		console.log 'socket: timeout...'
		socket.destroy()

server.listen 9000,DOMAIN_NAME

