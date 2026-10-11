{{flutter_js}}
{{flutter_build_config}}
// Push owns this scope. Never register Flutter's offline/cache worker: it can
// replace the push worker and must not intercept authenticated API traffic.
_flutter.loader.load();
