// Generated by CoffeeScript 1.9.0
(function() {
  var Server, header, header2, net, socket;

  Server = require('../class');

  header = 'GET /images HTTP/1.1\r\nHost: localhost:9000\r\n';

  header2 = '\r\n22222';

  net = require('net');

  socket = new net.Socket();

  socket.connect(9000, 'localhost', function() {
    console.log('connected to server!', socket.remoteAddress, socket.remotePort);
    socket.write(header);
    return socket.write(header2);
  });

  socket.on('data', function(data) {
    console.log("<<<<<< DATA >>>>>>");
    console.log(data.toString());
    return socket.end();
  });

  socket.on('error', function(err) {
    return console.log('client : error', err);
  });

  socket.on('end', function() {
    return console.log('disconnected from server');
  });

}).call(this);

//# sourceMappingURL=unitTestWebServer.js.map