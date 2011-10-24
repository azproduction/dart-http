#import('HttpServer.dart');
#import('HttpRequest.dart');
#import('HttpResponse.dart');

final int PORT = 5000;
final String HOST = "127.0.0.1";
final int MAX_CONNECTIONS = 100;

main() {
    HttpServer server = new HttpServer()
    .handler((HttpRequest request, HttpResponse response) {
        response.status(403)
        .send('pewpew ${request.headers["Connection"]}');
    })
    .listen(PORT, HOST, MAX_CONNECTIONS);

    print("accepting connections on ${server.host}:${server.port} @ ${server.connections}");
}