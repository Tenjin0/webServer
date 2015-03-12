Dog = require './dog'

doggy = new Dog 'Tony'

console.log doggy.getName()
doggy.prepare_fetch_later()
doggy.retrieveName 'name', (name) ->
	console.log doggy.getName()
