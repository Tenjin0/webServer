// Generated by CoffeeScript 1.9.0

/* reference
	http://curl.haxx.se/rfc/cookie_spec.html
 */

(function() {
  var AUTHORIZED_PATH, COOKIE_REGEX, Cookie, DEFAULT_EXTENSION, DEFAULT_PROTOCOL, DOMAIN_NAME, ErrorHtml, FIRST_LINE_REGEX, NAME_VALUE_REGEX, REQUEST_HOST_REGEX, REQUEST_PATH_REGEX, ROOT, RequestHeader, Response, SESSION_ID, SETCOOKIE, SessionCookie, conf, contentTypeMap, fs, host, net, path, sessionId, statusMessages,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __hasProp = {}.hasOwnProperty;

  fs = require('fs');

  net = require('net');

  path = require('path');

  conf = JSON.parse(fs.readFileSync(path.join(__dirname, '/conf/local.json'), 'utf8'));

  DOMAIN_NAME = 'localhost';

  SETCOOKIE = 'Set-Cookie';

  ROOT = path.join(__dirname, conf.contentFolderPath);

  sessionId = 1;

  DEFAULT_PROTOCOL = 'HTTP/1.0';

  DEFAULT_EXTENSION = '.html';

  SESSION_ID = "sessionId";

  FIRST_LINE_REGEX = new RegExp("^(GET|POST|HEAD) ([\/].*) (HTTP\/[01]\.[0-9])$");

  AUTHORIZED_PATH = new RegExp(ROOT + ".*");

  host = "Host";

  REQUEST_HOST_REGEX = new RegExp(host + ": ((.*):([]|[0-9]{4}))");

  REQUEST_PATH_REGEX = new RegExp("" + "\/$");

  COOKIE_REGEX = new RegExp("Cookie: (([^;]*=[^;]*;)*[^;]*=[^;]*)$");

  NAME_VALUE_REGEX = new RegExp("(.*)=(.*)");

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
    403: "Forbidden",
    404: "Not Found",
    414: "Request-URI Too Long",
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

  ErrorHtml = (function() {
    function ErrorHtml(code) {
      this.body = "<!DOCTYPE html> <html> <head> <title>Webserver Test</title> <meta charset='utf-8'> </head> <body> <H2>" + code + " " + statusMessages[code] + "</H2> </body> </html>\n";
    }

    ErrorHtml.prototype.getBody = function() {
      return this.body;
    };

    ErrorHtml.prototype.length = function() {
      return Buffer.byteLength(this.body, 'utf8');
    };

    return ErrorHtml;

  })();

  RequestHeader = (function() {
    function RequestHeader(socket, data) {
      var requestLine, _ref;
      requestLine = this.parseRequestHeader(socket, data);
      if (requestLine) {
        this.method = requestLine.method;
        this.protocol = requestLine.protocol;
        this.path = requestLine.path;
        this.host = (_ref = requestLine.host) != null ? _ref : null;
        this.originalPath = requestLine.originalPath;
        this.cookies = this.transformCookies(requestLine.cookies);
      } else {
        throw new Error('RequestHeader not create');
      }
    }

    RequestHeader.prototype.parseRequestHeader = function(socket, data) {
      var firstLine, i, index, line, match, match2, matchCookie, matchHost, requestLine, requestLines, split, _i, _j, _len, _len1;
      requestLines = data.toString().split("\r\n");
      firstLine = requestLines.splice(0, 1)[0];
      firstLine.match(FIRST_LINE_REGEX);
      if (match = firstLine.match(FIRST_LINE_REGEX)) {
        requestLine = {};
        requestLine['method'] = match[1];
        requestLine['protocol'] = match[3];
        for (index = _i = 0, _len = requestLines.length; _i < _len; index = ++_i) {
          line = requestLines[index];
          if (matchHost = line.match(REQUEST_HOST_REGEX)) {
            requestLine.host = {
              domain: matchHost[2],
              port: matchHost[3]
            };
          } else {
            requestLine.host = {
              domain: socket.remoteAddress,
              port: socket.localPort
            };
          }
          if (matchCookie = line.match(COOKIE_REGEX)) {
            requestLine['cookies'] = [];
            split = matchCookie[1].split("; ");
            for (_j = 0, _len1 = split.length; _j < _len1; _j++) {
              i = split[_j];
              match2 = i.match(NAME_VALUE_REGEX);
              requestLine.cookies[match2[1]] = match2[2];
            }
          }
        }
        requestLine['originalPath'] = match[2];
        requestLine['path'] = match[2].match(REQUEST_PATH_REGEX) ? path.join(match[2], "index.html") : match[2];
        return requestLine;
      } else {
        return null;
      }
    };

    RequestHeader.prototype.transformCookies = function(cookiesArray) {
      var cookies, i, v;
      cookies = [];
      for (i in cookiesArray) {
        v = cookiesArray[i];
        cookies.push(new Cookie(i, v));
      }
      return cookies;
    };

    RequestHeader.prototype.getCookies = function() {
      return this.cookies;
    };

    RequestHeader.prototype.getCookieSession = function() {
      var i, v, _ref;
      _ref = this.cookies;
      for (i in _ref) {
        v = _ref[i];
        if (i === SESSION_ID) {
          return new Cookie(i, v);
        }
      }
      return null;
    };

    RequestHeader.prototype.getDomain = function() {
      if (this.host) {
        return this.host.domain;
      } else {
        return null;
      }
    };

    return RequestHeader;

  })();

  Cookie = (function() {
    function Cookie(name, value, domain) {
      this.name = name;
      this.value = value;
      this.fields = {
        date: null,
        domain: null,
        path: null
      };
      if (domain) {
        this.fields['domain'] = null;
      }
      this.fields['path'] = "/";
      this.fields['date'] = null;
    }

    Cookie.prototype.setDomain = function(domain) {
      return this.domain = domain;
    };

    Cookie.prototype.setPath = function(path) {
      return this.path = path;
    };

    Cookie.prototype.toString = function() {
      var i, str, v, _ref;
      str = this.name + "=" + this.value;
      _ref = this.fields;
      for (i in _ref) {
        v = _ref[i];
        str += v ? "; " + i + "=" + v : "";
      }
      return str += this.secure ? "; secure" : "";
    };

    return Cookie;

  })();

  SessionCookie = (function(_super) {
    __extends(SessionCookie, _super);

    function SessionCookie(domain) {
      SessionCookie.__super__.constructor.call(this, SESSION_ID, sessionId++, domain);
    }

    return SessionCookie;

  })(Cookie);

  Response = (function() {
    var createReaderStream;

    function Response() {
      this.response = {
        header: {
          fields: {
            SETCOOKIE: []
          }
        },
        body: null
      };
    }

    Response.prototype.getResponseInfo = function(socket, requestLineData, callback) {
      return fs.stat(path.join(ROOT, requestLineData['path']), function(err, stats) {
        var error, errorHtml, responseEntity, tempContentSize, tempErrorHtml, tempExtension, tempPath, tempReadStream, tempStatusCode;
        tempExtension = DEFAULT_EXTENSION;
        tempPath = requestLineData['path'];
        if (requestLineData.method === 'GET' && Buffer.byteLength(path.basename(requestLineData.path), 'utf8') > 255) {
          tempPath = null;
          tempStatusCode = 414;
        } else if (err) {
          try {
            err = fs.accessSync(path.join(ROOT, requestLineData.originalPath), fs.R_OK);
            tempPath = requestLineData.originalPath;
            tempStatusCode = 403;
          } catch (_error) {
            error = _error;
            tempPath = null;
            tempStatusCode = 404;
          }
        } else if (AUTHORIZED_PATH.test(path.join(ROOT, tempPath))) {
          if (stats.isDirectory()) {
            tempPath = path.join(tempPath, '/');
            tempStatusCode = 302;
          } else if (stats.isFile()) {
            tempStatusCode = 200;
            tempContentSize = stats['size'];
            tempExtension = path.extname(tempPath.toLowerCase());
          }
        } else {
          tempStatusCode = 403;
        }
        if (tempStatusCode !== 200 && tempStatusCode !== 302) {
          errorHtml = new ErrorHtml(tempStatusCode);
          tempErrorHtml = errorHtml.getBody();
          tempContentSize = errorHtml.length();
        }
        tempReadStream = createReaderStream(socket, tempPath, tempStatusCode);
        responseEntity = {
          method: requestLineData.method,
          host: requestLineData.host,
          protocol: requestLineData.protocol,
          extension: tempExtension,
          referer: requestLineData.originalPath,
          path: tempPath,
          statusCode: tempStatusCode,
          contentSize: tempContentSize,
          readStream: tempReadStream,
          errorHtml: tempErrorHtml
        };
        return callback(responseEntity);
      });
    };

    Response.prototype.addCookies = function(cookies) {
      return this.response.header.fields[SETCOOKIE] = this.response.header.fields[SETCOOKIE].concat(cookies);
    };

    Response.prototype.addCookie = function(cookie) {
      return this.response.header.fields[SETCOOKIE].push(cookie);
    };

    createReaderStream = function(socket, relativePath, statusCode) {
      var readStream;
      if (statusCode === 200) {
        readStream = fs.createReadStream(path.join(ROOT, relativePath));
        readStream.on('end', function() {
          return socket.end();
        });
        readStream.on('error', function(err) {
          return socket.end();
        });
        return readStream;
      } else {
        return null;
      }
    };

    Response.prototype.createResponse = function(socket, requestData, callback) {
      return this.getResponseInfo(socket, requestData, (function(_this) {
        return function(responseEntity) {
          _this.response = {
            header: _this.createResponseHeader(responseEntity),
            body: _this.createResponseBody(responseEntity)
          };
          return callback();
        };
      })(this));
    };

    Response.prototype.createResponseHeader = function(responseInfo) {
      var responseHeader, toString, _ref;
      responseHeader = {
        statusLine: responseInfo.protocol + " " + responseInfo.statusCode + " " + statusMessages[responseInfo.statusCode],
        fields: {
          'Content-Type': (_ref = contentTypeMap[responseInfo.extension]) != null ? _ref : 'text/plain',
          'Date': new Date(),
          'Content-Length': responseInfo.contentSize && responseInfo.method !== 'HEAD' ? responseInfo.contentSize : 0,
          'Connection': 'close',
          'Set-Cookie': []
        }
      };
      if (responseInfo.statusCode === 302 || responseInfo.statusCode === 301) {
        responseHeader.fields['Location'] = "http://" + (path.join(responseInfo.host.domain + ":" + responseInfo.host.port, responseInfo['path']));
      }
      toString = function() {
        var i, ind, str, v, val, _ref1;
        str = responseHeader['statusLine'] + "\r\n";
        _ref1 = responseHeader['fields'];
        for (i in _ref1) {
          v = _ref1[i];
          if (i === SETCOOKIE) {
            for (ind in v) {
              val = v[ind];
              str += i + ": " + val.name + "=" + val.value + "; path=" + val.fields.path + "\r\n";
            }
          } else {
            str += i + ': ' + v + "\r\n";
          }
        }
        return str + '\r\n';
      };
      return {
        statusLine: responseHeader.statusLine,
        fields: responseHeader.fields,
        toString: toString
      };
    };

    Response.prototype.createResponseBody = function(info) {
      var responseBody;
      responseBody = {
        extension: info.extension
      };
      if (info.method === 'GET' || info.method === 'POST') {
        responseBody['readStream'] = info.readStream;
        responseBody['errorHtml'] = info.errorHtml;
      } else {
        responseBody['readStream'] = null;
        responseBody['errorHtml'] = null;
      }
      return responseBody;
    };

    Response.prototype.sendResponse = function(socket) {
      return socket.write(this.response.header.toString(), (function(_this) {
        return function() {
          if (_this.response.body.readStream) {
            return _this.response.body.readStream.pipe(socket);
          } else {
            if (_this.response.header.statusCode === 302 || !_this.response.body.errorHtml) {
              return socket.end();
            } else {
              return socket.write(_this.response.body.errorHtml);
            }
          }
        };
      })(this));
    };

    Response.prototype.getResponse = function() {
      return this.response;
    };

    Response.prototype.getCookies = function() {
      return this.response.header.fields[SETCOOKIE];
    };

    return Response;

  })();

  module.exports = {
    DEFAULT_PROTOCOL: DEFAULT_PROTOCOL,
    DEFAULT_EXTENSION: DEFAULT_EXTENSION,
    DOMAIN_NAME: DOMAIN_NAME,
    ROOT: ROOT,
    SESSION_ID: SESSION_ID,
    SETCOOKIE: SETCOOKIE,
    AUTHORIZED_PATH: AUTHORIZED_PATH,
    FIRST_LINE_REGEX: FIRST_LINE_REGEX,
    NAME_VALUE_REGEX: NAME_VALUE_REGEX,
    REQUEST_HOST_REGEX: REQUEST_HOST_REGEX,
    REQUEST_PATH_REGEX: REQUEST_PATH_REGEX,
    contentTypeMap: contentTypeMap,
    statusMessages: statusMessages,
    Cookie: Cookie,
    ErrorHtml: ErrorHtml,
    RequestHeader: RequestHeader,
    Response: Response,
    SessionCookie: SessionCookie
  };

}).call(this);

//# sourceMappingURL=class.js.map
