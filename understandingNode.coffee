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



ind = 1
console.log 'starting a long operation for request:', id
setTimeout ( -> console.log 'ending a long operation for request:', id),3000
ind = 2
console.log 'starting a long operation for request:', id
setTimeout ( -> console.log 'ending a long operation for request:', id), 3000

console.log '\n\n'

ind = 3
console.log 'starting a long operation for request:', ind
setTimeout (->
	console.log 'ending a long operation for request:', ind
	) ,0
ind = 4
console.log 'starting a long operation for request:', ind
setTimeout (->
	console.log 'ending a long operation for request:', ind
	) ,0


