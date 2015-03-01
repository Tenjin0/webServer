// Generated by CoffeeScript 1.9.0
(function() {
  var HTTPParser, arrayContains, chemin, constructHeader, dataToArray, fs, html, httpRequest, isNotEmpty, net, options, path, requestLine, requestLineHeaderJSON, root, server, statusCode;

  fs = require('fs');

  net = require('net');

  path = require('path');

  HTTPParser = process.binding('http_parser').HTTPParser;

  root = __dirname + '/webroot';

  httpRequest = "GET / HTTP/1.0\r\n Host: patrice:3333\r\n Connection: keep-alive\r\n Cache-Control: max-age=0\r\n Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\n User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/40.0.2214.111 Chrome/40.0.2214.111 Safari/537.36\r\n Accept-Encoding: gzip, deflate, sdch\r\n Accept-Language: fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4\r\n";

  html = "<!DOCTYPE html> <html> <head> <title>Webserver Test</title> <meta charset='utf-8'> </head> <body> Ceci est le body </body> </html>";

  options = {
    allowHalfOpen: false,
    pauseOnConnect: false
  };

  statusCode = [
    {
      "200": "OK",
      "201": "Created",
      "202": "Accepted",
      "204": "No Content",
      "301": "Moved Permanently",
      "302": "Moved Temporarily",
      "304": "Not Modified",
      "400": "Bad Request",
      "401": "Unauthorized",
      "403": "Forbidden",
      "404": "Not Found",
      "500": "Internal Server Error",
      "501": "Not Implemented",
      "502": "Bad Gateway",
      "503": "Service Unavailable"
    }
  ];

  requestLine = function(data) {
    var array, requestLineArray, requestLineJSON;
    array = dataToArray(data);
    requestLineArray = array[0];
    requestLineJSON = {
      "method": requestLineArray[0],
      "path": requestLineArray[1],
      "protocol": requestLineArray[2]
    };
    return requestLineJSON;
  };

  isNotEmpty = function(element) {
    return !(element === '');
  };

  dataToArray = function(data) {
    var array, i, _i, _ref;
    array = data.toString().split("\r\n");
    array = array.filter(isNotEmpty);
    for (i = _i = 0, _ref = array.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      array[i] = array[i].split(" ");
    }
    return array;
  };

  arrayContains = function(array, data) {
    var value, _i, _len;
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      value = array[_i];
      if (value === data) {
        return true;
      }
    }
    return false;
  };

  constructHeader = function(protocole, code, ext) {
    return protocole + " " + code + " " + statusCode[code] + "\r\n" + "Content-Type: text/" + ext + "\r\n";
  };

  requestLineHeaderJSON = requestLine(httpRequest);

  console.log('firstLineHeaderJSON', requestLineHeaderJSON);

  chemin = requestLineHeaderJSON['path'];

  chemin = chemin === '/' ? 'index.html' : chemin;

  console.log('path : ', chemin);

  server = net.createServer(options, function(socket) {
    var closeSocket, connectSocket, connectionSocket, dataSocket, errorSocket, parser;
    parser = new HTTPParser(HTTPParser.REQUEST);
    console.log('parserServer', parser);
    socket.on('connection', connectionSocket = function() {
      return console.log('socket : connection' + socket.remoteAddress(+':' + socket.remotePort + "\n"));
    });
    socket.on('connect', connectSocket = function() {
      return console.log('socket : connect');
    });
    socket.on('data', dataSocket = function(data) {
      var extension, filePath, header, readStream;
      requestLineHeaderJSON = requestLine(data);
      chemin = requestLineHeaderJSON['path'];
      chemin = chemin === '/' || '' ? 'index.html' : chemin;
      extension = path.extname(filePath.toLowerCase());
      filePath = path.join(root, chemin);
      console.log('search ', filePath);
      readStream = fs.createReadStream(filePath);
      header = constructHeader(requestLineHeaderJSON['protocol'], "200", extension);
      socket.write(header200);
      socket.write('\r\n');
      socket.write('\r\n');
      readStream.on('open', function() {
        console.log('readStream ouvert');
        return readStream.pipe(socket);
      });
      return readStream.on('close', function() {
        return console.log('readStream close');
      });
    });
    socket.on('error', errorSocket = function() {
      return console.log('socket : error');
    });
    return socket.on('close', closeSocket = function() {
      return console.log('socket : close');
    });
  });

  server.listen(9000, 'localhost');

}).call(this);
