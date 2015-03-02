http = require 'http'
nodestatic = require 'node-static'

web = new nodestatic.Server './webroot'

server = http.createServer (request, response)->
	request.addListener('end', -> web.serve request, response).resume()

server.listen 8081
