// Generated by CoffeeScript 1.9.0
(function() {
  var AUTHORIZED_PATH, DEFAULT_EXTENSION, DEFAULT_PROTOCOL, FIRST_LINE_REGEX, METHOD_REGEX, ROOT, ServerOptions, conf, contentTypeMap, createAbsolutePath, createErrorHtml, createResponseHeader, fs, net, parseStatusLine, path, sendResponse, server, statusMessages;

  fs = require('fs');

  net = require('net');

  path = require('path');

  conf = JSON.parse(fs.readFileSync('conf/local.json', 'utf8'));

  ROOT = path.join(__dirname, conf.contentFolderPath);

  DEFAULT_PROTOCOL = 'HTTP/1.0';

  DEFAULT_EXTENSION = '.html';

  FIRST_LINE_REGEX = new RegExp("(GET|POST|HEAD)[ ]([\/].*[ ]){1,}HTTP\/1\.[0-9]");

  AUTHORIZED_PATH = new RegExp(ROOT + ".*");

  METHOD_REGEX = new RegExp("(GET|POST|HEAD)");

  statusMessages = {
    200: "OK",
    201: "Created",
    202: "Accepted",
    204: "No Content",
    301: "Moved Permanently",
    302: "Moved Temporarily",
    304: "Not Modified",
    400: "Bad Request",
    401: "Unauthorized",
    403: "Forbidden Acces",
    404: "Not Found",
    500: "Internal Server Error",
    501: "Not Implemented",
    502: "Bad Gateway",
    503: "Service Unavailable"
  };

  contentTypeMap = {
    '.jpg': 'image/jpg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.bmp': 'image/bmp',
    '.gif': 'image/gif',
    '.js': 'application/javascript',
    '.mp4': 'video/mp4',
    '.mp3': 'audio/mp3',
    '.html': 'text/html',
    '.css': 'text/css'
  };

  createErrorHtml = function(code) {
    return {
      body: "<!DOCTYPE html> <html> <head> <title>Webserver Test</title> <meta charset='utf-8'> </head> <body> <H2>" + code + " " + statusMessages[code] + "</H2> </body> </html>\n"
    };
  };

  createAbsolutePath = function(relativePath, callback) {
    return fs.stat(path.join(ROOT, relativePath), function(err, stats) {
      console.log(err, stats);
      if (err) {
        return callback(null, err);
      } else if (stats.isDirectory()) {
        return fs.open(path.join(ROOT, relativePath, 'index.html'), 'r', function(err, fd) {
          if (err) {
            return callback(path.join(ROOT, relativePath), null);
          } else {
            return callback(path.join(ROOT, relativePath, 'index.html'), null);
          }
        });
      } else {
        return callback(path.join(ROOT, relativePath), null);
      }
    });
  };

  parseStatusLine = function(data, callback) {
    var firstLine, requestLineArray;
    firstLine = (data.toString().split("\r\n"))[0];
    if (FIRST_LINE_REGEX.test(firstLine)) {
      requestLineArray = firstLine.split(" ");
      return createAbsolutePath(requestLineArray[1], function(path, err) {
        var requestLineJSON;
        if (path) {
          return callback(requestLineJSON = {
            'method': requestLineArray[0],
            'path': path,
            'protocol': requestLineArray[2]
          });
        } else {
          return callback(null);
        }
      });
    } else {
      return callback(null);
    }
  };

  createResponseHeader = function(code, ext, fileLength) {
    var responseHeader, _ref;
    responseHeader = {
      statusLine: DEFAULT_PROTOCOL + " " + code + " " + statusMessages[code],
      fields: {
        'content-Type': (_ref = contentTypeMap[ext]) != null ? _ref : 'text/plain',
        'Date': new Date(),
        'Content-Length': fileLength != null ? fileLength : 0,
        'Connection': 'close'
      }
    };
    return {
      toString: function() {
        var i, str, v, _ref1;
        str = responseHeader['statusLine'] + "\r\n";
        _ref1 = responseHeader['fields'];
        for (i in _ref1) {
          v = _ref1[i];
          str += i + ': ' + v + "\r\n";
        }
        return str + '\r\n';
      }
    };
  };

  sendResponse = function(socket, header, statusCode, readStream) {
    return socket.write(header.toString(), function() {
      if (readStream) {
        return readStream.pipe(socket);
      } else {
        return socket.end((createErrorHtml(statusCode))['body']);
      }
    });
  };

  ServerOptions = {
    allowHalfOpen: false,
    pauseOnConnect: false
  };

  server = net.createServer(ServerOptions, function(socket) {
    return socket.on('data', function(data) {
      var statusCode;
      statusCode = 400;
      return parseStatusLine(data, function(statusLine, error) {
        var extension, responseHeader;
        console.log("statusLine", statusLine);
        if (statusLine) {
          extension = path.extname(statusLine['path'].toLowerCase());
          fs.stat(statusLine['path'], function(err, stats) {
            var fileSize, readStream, responseHeader;
            if (err) {
              statusCode = 404;
            } else if (stats.isDirectory() || !AUTHORIZED_PATH.test(statusLine['path'])) {
              statusCode = 403;
            } else if (stats.isFile()) {
              statusCode = 200;
              fileSize = stats["size"];
              readStream = fs.createReadStream(statusLine['path']);
              readStream.on('end', function() {
                return socket.end();
              });
            }
            if (!fileSize) {
              extension = DEFAULT_EXTENSION;
              fileSize = Buffer.byteLength((createErrorHtml(statusCode))['body'], 'utf8');
            }
            responseHeader = createResponseHeader(statusCode, extension, fileSize);
            console.log(statusLine['path']);
            console.log(responseHeader.toString());
            return sendResponse(socket, responseHeader, statusCode, readStream);
          });
        } else {
          responseHeader = createResponseHeader(statusCode);
          sendResponse(socket, responseHeader, statusCode);
        }
        return socket.on('error', function(err) {
          return console.log('socket: error', err);
        });
      });
    });
  });

  server.listen(9000, 'localhost');

}).call(this);
