import 'dart:html' as html;

void cleanAuthCallbackUrl() {
  final uri = Uri.base;
  if (uri.path == '/login-callback' || uri.queryParameters.containsKey('code')) {
    final cleaned = uri.replace(path: '/', query: '').toString();
    html.window.history.replaceState(null, 'Ders Takip', cleaned);
  }
}
