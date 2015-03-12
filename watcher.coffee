class Watcher
	pendingRequests: 0

	onCompletion: (callback) ->
		@completionCallback = callback
		@maybeComplete()

	requestStarted: ->
		@pendingRequests++

	requestFinished: ->
		@pendingRequests-- if @pendingRequests > 0

	requestFailed: ->
		@completionCallback = null

	maybeComplete: ->
		if @pendingRequests is 0
			@completionCallback?()
			@completionCallback = null

watcher = new Watcher()
console.log watcher
watcher.requestStarted()
console.log watcher.pendingRequests
console.log watcher.maybeComplete()
