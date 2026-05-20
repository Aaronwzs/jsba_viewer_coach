{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    
    // Smooth fade out of the loader to reveal the app
    const loader = document.getElementById('loading_indicator');
    if (loader) {
      loader.classList.add('fade-out');
      
      // Wait for CSS transition (400ms) to complete before removing the DOM element
      setTimeout(() => {
        loader.remove();
      }, 400);
    }
    
    await appRunner.runApp();
  }
});
