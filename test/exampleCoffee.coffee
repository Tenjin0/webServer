http = require 'http'
hbs = require 'hbs'
express = require 'express'
app = express()

app.set 'view engine', 'html'
app.engine 'html', hbs.__express



app.get '/', (req, res) ->
	res.render 'example'
app.use "/javascripts", express.static(__dirname + "/javascripts")
app.use (req, res, next) ->
	res.redirect '/'
	next()
app.listen 4000
