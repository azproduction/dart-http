/**
 * Simple HTTP server on Dart
 * @see http://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/runtime/bin/socket_impl.dart
 *      http://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/runtime/bin/socket_stream.dart
 *
 * Based on http://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/samples/socket/SocketExample.dart
 * @author azproduction
 */
#library('HttpServer.dart');

class HttpRequest {
    final RegExp REQUEST_STRING_PARSER = const RegExp('([A-Z]{2,5})\\s([^\\s]+)\\sHTTP/(.*)');

    Map<String, String> headers;
    String query;
    String method;
    String version;
    String body;

    HttpRequest(this.method, this.query, this.version, this.headers) {}

    HttpRequest.fromResultBuffer(List<int> resultBuffer) {
        String requestBody = new String.fromCharCodes(resultBuffer);
        Queue<String> parts = new Queue<String>.from(requestBody.split('\r\n'));
        String request = parts.removeFirst();
        body = parts.removeLast();
        parts.removeLast();

        Match match = REQUEST_STRING_PARSER.allMatches(request)[0];

        method = match.group(1);
        query = match.group(2);
        version = match.group(3);
        headers = new Map<String, String>();

        parts.forEach((String item) {
            List<String> headerParts = item.split(': ');
            headers[headerParts[0]] = headerParts[1];
        });
    }
}

class HttpResponse {
    final String DEFAULT_SERVER_NAME = 'Dart';

    final Map<String, String> STATUS_CODES = const <String, String> {
        "100": "Continue",
        "101": "Switching Protocols",
        "102": "Processing",
        "200": "OK",
        "201": "Created",
        "202": "Accepted",
        "203": "Non-Authoritative Information",
        "204": "No Content",
        "205": "Reset Content",
        "206": "Partial Content",
        "207": "Multi-Status",
        "300": "Multiple Choices",
        "301": "Moved Permanently",
        "302": "Moved Temporarily",
        "303": "See Other",
        "304": "Not Modified",
        "305": "Use Proxy",
        "307": "Temporary Redirect",
        "400": "Bad Request",
        "401": "Unauthorized",
        "402": "Payment Required",
        "403": "Forbidden",
        "404": "Not Found",
        "405": "Method Not Allowed",
        "406": "Not Acceptable",
        "407": "Proxy Authentication Required",
        "408": "Request Time-out",
        "409": "Conflict",
        "410": "Gone",
        "411": "Length Required",
        "412": "Precondition Failed",
        "413": "Request Entity Too Large",
        "414": "Request-URI Too Large",
        "415": "Unsupported Media Type",
        "416": "Requested Range Not Satisfiable",
        "417": "Expectation Failed",
        "418": "I'm a teapot",
        "422": "Unprocessable Entity",
        "423": "Locked",
        "424": "Failed Dependency",
        "425": "Unordered Collection",
        "426": "Upgrade Required",
        "500": "Internal Server Error",
        "501": "Not Implemented",
        "502": "Bad Gateway",
        "503": "Service Unavailable",
        "504": "Gateway Time-out",
        "505": "HTTP Version not supported",
        "506": "Variant Also Negotiates",
        "507": "Insufficient Storage",
        "509": "Bandwidth Limit Exceeded",
        "510": "Not Extended"
    };

    Map<String, String> headers;
    String responseBody = '';
    int statusCode = 200;
    String httpVersion = '1.1';
    Socket outputSocket;

    HttpResponse(Socket sock): headers = new Map<String, String>() {
        outputSocket = sock;
    }

    void _onWrite(List<int> output, int offset) {
        int written = outputSocket.writeList(output, offset, output.length - offset);
        if (written > 0 && written < output.length - offset) {
            outputSocket.setWriteHandler(() => _onWrite(output, offset + written));
        } else {
            outputSocket.close();
        }
    }

    List<int> _createResponse() {
        if (headers['Server'] == null) {
            headers['Server'] = DEFAULT_SERVER_NAME;
        }

        String headersString = '';

        headers.forEach((String header, String headerValue) {
            headersString += '$header: $headerValue\r\n';
        });

        String statusCodeText = STATUS_CODES[statusCode.toString()];
        return "HTTP/$httpVersion $statusCode $statusCodeText\r\n$headersString\r\n$responseBody".charCodes();
    }

    HttpResponse header(String headerName, String headerValue) {
        headers[headerName] = headerValue;
        return this;
    }

    HttpResponse status(int status) {
        statusCode = status;
        return this;
    }

    HttpResponse version(String version) {
        httpVersion = version;
        return this;
    }

    void send(String body) {
        responseBody = body;
        outputSocket.setWriteHandler(() => _onWrite(_createResponse(), 0));
    }
}

class HttpServer {
    String host;
    int port;
    ServerSocket serverSocket;
    Function callback;

    HttpServer([String serverHost = "127.0.0.1", int serverPort = 80]) {
        host = serverHost;
        port = serverPort;
    }

    HttpServer listen(cb(HttpRequest request, HttpResponse response)) {
        // initialize the server
        serverSocket = new ServerSocket(host, port, 5);
        if (serverSocket == null) {
            throw "can't get server socket";
        }

        callback = cb;
        serverSocket.setConnectionHandler(_onConnect);
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

    void _onClose(Socket sock) {
        sock.close();
    }

    void _onConnect() {
        Socket receiveSocket = serverSocket.accept();
        receiveSocket.setCloseHandler(() => this._onClose(receiveSocket));
        receiveSocket.setDataHandler(() => this._onData(receiveSocket));
        return;
    }
}