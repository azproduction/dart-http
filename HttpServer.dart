/**
 * Simple HTTP server on Dart
 * @see http://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/runtime/bin/socket_impl.dart
 *      http://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/runtime/bin/socket_stream.dart
 *
 * Based on http://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/samples/socket/SocketExample.dart
 * @author azproduction
 */
#library('HttpServer.dart');

#import('HttpRequest.dart');
#import('HttpResponse.dart');

class HttpServer {
    String host;
    int port;
    int connections;
    ServerSocket serverSocket;
    Function callback;

    HttpServer([void cb(HttpRequest request, HttpResponse response)]) {
        handler(cb);
    }

    HttpServer listen([int serverPort = 80, String serverHost = "127.0.0.1", int maxConnections = 100]) {
        // initialize the server
        host = serverHost;
        port = serverPort;
        connections = maxConnections;

        if (callback == null) {
            throw "no handler";
        }

        serverSocket = new ServerSocket(host, port, connections);

        if (serverSocket == null) {
            throw "can't get server socket";
        }

        serverSocket.setConnectionHandler(_onConnect);
        return this;
    }

    HttpServer handler(cb(HttpRequest request, HttpResponse response)) {
        callback = cb;
        return this;
    }

    void _onRead(Socket sock, List<int> resultBuffer) {
        int i = 0;
        for (; i < resultBuffer.length; i++) {
            if (resultBuffer[i] == null) {
                break;
            }
        }
        resultBuffer = new List<int>.fromList(resultBuffer, 0, i - 1);
        callback(new HttpRequest.fromResultBuffer(resultBuffer), new HttpResponse(sock));
    }

    void _onData(Socket sock) {
        List<int> resultBuffer = new List<int>(65535);
        bool incomplete = sock.inputStream.read(resultBuffer, 0, resultBuffer.length, () {
            this._onRead(sock, resultBuffer);
        });

        if (!incomplete) {
            this._onRead(sock, resultBuffer);
        }
    }

    void _onConnect() {
        Socket receiveSocket = serverSocket.accept();
        receiveSocket.setDataHandler(() => this._onData(receiveSocket));
        return;
    }
}