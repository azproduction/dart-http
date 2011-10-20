Simple server setup
===================

'''java

    #import('HttpServer.dart');
    
    main() {
        HttpServer server = new HttpServer("127.0.0.1", 5000);
    
        server.listen((HttpRequest request, HttpResponse response) {
            response.status(403).send('pewpew ${request.headers["Connection"]}');
        });
    
        print("accepting connections on ${server.host}:${server.port}");
    }

'''