{{flutter_js}}
{{flutter_build_config}}

// Safety net: force-remove loader after 8 seconds if Flutter hasn't started
setTimeout(function() {
  var loader = document.getElementById('loading_indicator');
  if (loader) {
    loader.classList.add('fade-out');
    setTimeout(function() { loader.remove(); }, 400);
  }
}, 8000);

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    
    // Smooth fade out of the loader to reveal the app
    var loader = document.getElementById('loading_indicator');
    if (loader) {
      loader.classList.add('fade-out');
      setTimeout(function() { loader.remove(); }, 400);
    }
  }
});
