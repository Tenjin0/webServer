statusCode =
	200 : "OK"
	201 : "Created"
	202 : "Accepted"
	204 : "No Content"
	301 : "Moved Permanently"
	302 : "Moved Temporarily"
	304 : "Not Modified"
	400 : "Bad Request"
	401 : "Unauthorized"
	403 : "Forbidden"
	404 : "Not Found"
	500 : "Internal Server Error"
	501 : "Not Implemented"
	502 : "Bad Gateway"
	503 : "Service Unavailable"


for index,value of statusCode
	( ->
		setTimeout (->
			console.log index, value
		), 100
	)

