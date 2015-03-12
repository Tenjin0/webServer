fs = require 'fs'

module.exports =
class Dog
	constructor: (name) ->
		@name = name
	fetch_later: ->
		@message_for_fetch_later()
	message_for_fetch_later: ->
		console.log "Ok, I will fetch that later."
	prepare_fetch_later: ->
		setTimeout((=> @message_for_fetch_later();return;),1000)
	getName : ->
		@name
	retrieveName: (file,callback)->
		fs.readFile file, (err,data) ->
			if err
				console.log 'err',err
			else
				@name = data.toString()
				console.log 'data',@name
				callback(@name)


