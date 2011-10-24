#library('HttpResponse.dart');

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
    bool _isSending = false;

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
        if (_isSending) {
            throw "Content already sent";
        }
        responseBody = body;
        _isSending = true;
        outputSocket.setWriteHandler(() => _onWrite(_createResponse(), 0));
    }
}