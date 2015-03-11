# beginning Node.js.pdf

# foo = {}
# foo.bar = 123
# console.log foo

# foo = {
# 	bar : 123
# }
# console.log foo

foo =
	bar: 'some string',
	bas:
		bas1 : "default"
		bas2 : 345
foo.bas['bas3']= 'another string'
console.log foo['bas']

foo =
	bar : 123
	bas : [
		"default",
		345
	]
foo.bas.push 'another string'
for i,v in foo.bas
	console.log v,i

foo =
	bar : 123
	bas : [
		{bas1 : "default"},
		{bas2 : 345}
	]
foo.bas.push({bas3 : 'another string'})
for i,v of foo.bas
	console.log i,v
	for j,v2 of foo.bas[i]
		console.log j,v2

longRunningFunction = (callback)->
	setTimeout(callback,3000)

webRequest = (request) ->
	console.log 'starting a long operation for request:', request.id
	longRunningFunction (console.log 'ending a long operation for request:', request.id),3000
# webRequest {id : 1}
# webRequest {id : 2}



# ind = 1
# console.log 'starting a long operation for request:', ind
# setTimeout ( -> console.log 'ending a long operation for request:', ind),3000
# ind = 2
# console.log 'starting a long operation for request:', ind
# setTimeout ( -> console.log 'ending a long operation for request:', ind), 3000

# console.log '\n\n'

# ind = 3
# console.log 'starting a long operation for request:', ind
# setTimeout (->
# 	console.log 'ending a long operation for request:', ind
# 	) ,0
# ind = 4
# console.log 'starting a long operation for request:', ind
# setTimeout (->
# 	console.log 'ending a long operation for request:', ind
# 	) ,0


console.time('timer')
setTimeout (->
	console.timeEnd('timer')
),1000

console.time('timeIt')
(fibonacci = (n) ->
	if n < 2
		return n
	else
		fibonacci(n-1) + fibonacci(n-2)
)(10)
console.timeEnd('timeIt')

# Everything is reference when modifing inside a function the attribute an object passed in parameter the change will be keeps after the return of th function / copy passed just the attribut in function parameter
foo =
	bas : 123
bar = foo
bar.bas = 456
console.log foo

#Truthy falsy

if (!false)
	console.log 'false: falsy'

if (!null)
	console.log 'null: falsy'

if (!undefined)
	console.log 'undefined: falsy'

if (!'')
	console.log '\'\': falsy'

if (!0)
	console.log '0:falsy'

if (1)
	console.log '1:Truthy'

if (2)
	console.log '2:Truthy'


# Module pattern : first class function, closure, litteral object

printableMessage = ->
	message = 'hello'

	getMessage = ->
		return message

	setMessage = (entry)->
		if !entry
			throw new Error('cannot set empty message')
		message = entry

	printMessage = ->
		console.log message

	{
		getMessage : getMessage
		setMessage : setMessage
		printMessage : printMessage
	}
mess = printableMessage()

mess.setMessage('toto')
mess2 = printableMessage()
mess.printMessage()
mess2.setMessage('au revoir')
mess2.printMessage()


foo = ->

foo.prototype.bar = 123
foo.ter = 456
bas = new foo()
# console.log bas.ter undefined
console.log '__proto__ and prototype',bas.__proto__.bar == foo.prototype.bar
console.log 'bas.bar', bas.bar
foo.prototype.bar = 789
bas2 = new foo()
console.log 'bas.bar',bas2.bar
