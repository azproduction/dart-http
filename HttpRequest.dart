#library('HttpRequest.dart');

class HttpRequest {
    final RegExp REQUEST_STRING_PARSER = const RegExp('([A-Z]{2,5})\\s([^\\s]+)\\sHTTP/(.*)');

    Map<String, String> _headers;
    String _query;
    String _method;
    String _version;
    String _body;
    List<int> _buffer;

    String get query() {
        if (_buffer != null) _parse();
        return _query;
    }

    String get method() {
        if (_buffer != null) _parse();
        return _method;
    }

    String get version() {
        if (_buffer != null) _parse();
        return _version;
    }

    String get body() {
        if (_buffer != null) _parse();
        return _body;
    }

    Map<String, String> get headers() {
        if (_buffer != null) _parse();
        return _headers;
    }

    HttpRequest(this._method, this._query, this._version, this._headers) {}
    HttpRequest.fromResultBuffer(this._buffer) {}

    _parse() {
        String requestBody = new String.fromCharCodes(_buffer);
        Queue<String> parts = new Queue<String>.from(requestBody.split('\r\n'));
        String request = parts.removeFirst();
        _body = parts.removeLast();
        parts.removeLast();

        Match match = REQUEST_STRING_PARSER.allMatches(request)[0];

        _method = match.group(1);
        _query = match.group(2);
        _version = match.group(3);
        _headers = new Map<String, String>();

        parts.forEach((String item) {
            List<String> headerParts = item.split(': ');
            _headers[headerParts[0]] = headerParts[1];
        });
        _buffer = null;
    }
}