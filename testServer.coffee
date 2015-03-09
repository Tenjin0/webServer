constructHeader = (protocole, code, ext, lengthFile) ->

	contentType = findContentTypeFile ext
	# console.log 'contentType',
	contentSubType = if contentType['replace'] is null then 'plain' else contentType['replace']
	#  console.log 'contenType', contentType, ext
	contentLength = if lengthFile then "Content-Length:" + lengthFile+ "\r\n" else ""
	contentExt = if ext then "Content-Type:" + contentType['type'] + '/' + contentSubType + "\r\n" else "\r\n"
	protocole+ " " + code + " " +  statusCode[code] + "\r\n" + contentExt + contentLength + "Connection: close"+ "\r\n"+ "\r\n"

dataToArray = (data)->

	array =  data.toString().split "\r\n"
	array = array.filter isNotEmpty	# console.log 'array',array
	for i in [0..array.length-1]
		array[i] = array[i].split " "
	return array

findContentTypeFile = (ext)->
	if !(ext is null)
		for i,tab of contentTypeMap
			index = tab['tab'].indexOf ext
			# console.log '>>>>>>>', i, tab, tab.indexOf ext
			if index >= 0
				return contentType =
					'type' : i
					'replace' : if tab['replace'] is undefined then ext else tab['replace']
		return options =
			'type' : 'text'
			'replace' : null

		return options =
			'type' : 'text'
			'replace' : null

isNotEmpty = (element)->

	return !(element is '')
# TEST

# console.log ["A", "B", "C"].indexOf("A")
# fileTest = "index.jpg"
# ext = path.extname fileTest
# ext = if ext.match (new RegExp ('[\.].*')) then ext.substring 1,ext.length else null
# console.log 'ext', ext



# console.log 'options', contentTypeFile ext
line1 = "Host: localhost:9000"
line2 = "Referer: http://localhost:9000/iframe"
host = "Host"

referer = "Referer"
REQUEST_HOST_REGEX = new RegExp "#{host}: "
REQUEST_REF_REGEX = new RegExp "#{referer}: "


# match =simpleHeader.match REQUEST_HOST_REGEX
# console.log REQUEST_HOST_REGEX
requestLine = {}
if line1.match REQUEST_HOST_REGEX
	# console.log 'line',line
	regexLength = REQUEST_HOST_REGEX.toString().replace(/\//g,"").length
	requestLine[host] = line1.substring regexLength, line1.length
if line2.match REQUEST_REF_REGEX
	# console.log 'line',line
	regexLength = REQUEST_REF_REGEX.toString().replace(/\//g,"").length
	requestLine[referer] = line2.substring regexLength, line2.length

regex = new RegExp requestLine[host]
console.log requestLine[referer].match regex
console.log requestLine[referer].substring ((requestLine[referer].match regex).index + requestLine[host].length), requestLine[referer].length
# str = REQUEST_HOST_REGEX.toString()
# console.log str
# console.log str.replace(/\//g,"").length
# console.log 'match', match.input.substring(str.replace(/\//g,"").length, simpleHeader.length)
# console.log 'match', match.substring(match.index, REQUEST_HOST_REGEX.length)

# console.log 'search', simpleHeader.search REQUESTLINEREGEX
# console.log 'test', REQUESTLINEREGEX.test simpleHeader
# console.log 'exec', REQUESTLINEREGEX.exec simpleHeader

# console.log FindContentTypeFile 'mp3',

# console.log 'options', options = FindContentTypeFile 'js'
# console.log newContentTypeMap
# console.log (createResponseHeader "HTTP/1.0" , 'html', 200).toString()
