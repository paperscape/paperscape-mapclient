({
    baseUrl: ".",
    paths: {
        "jquery": "lib/jquery-3.1.1.min",
        "jquery.mousewheel": "lib/jquery.mousewheel",
        "jquery.autocomplete": "lib/jquery-ui-autocomplete.min",
        "jquery.autocomplete.html": "lib/jquery-ui-autocomplete.html",
        "requireLib": "lib/require"
    },
    shim: {
      "jquery.mousewheel": {
        deps: ["jquery"]
      },
      "jquery.autocomplete": {
        deps: ["jquery"]
      },
      "jquery.autocomplete.html": {
        deps: ["jquery", "jquery.autocomplete"]
      }
    },
    wrapShim: true,
    name: "app/config",
    include: "requireLib",
    out: "app-build/pscp.js"
})
