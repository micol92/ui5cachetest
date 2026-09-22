sap.ui.define(["sap/ui/core/mvc/XMLView"], function (XMLView) {
  "use strict";

  function loadRoute() {
    var route = (window.location.hash || "#/CarRegistration").replace("#/", "");
    var contentEl = document.getElementById("content");
    contentEl.innerHTML = "";
    XMLView.create({ viewName: "hashdemo.view." + route })
      .then(function (oView) {
        oView.placeAt("content");
      })
      .catch(function (e) {
        console.error("[hashdemo] " + route + " view load failed:", e);
      });
  }

  window.addEventListener("hashchange", loadRoute);
  loadRoute();
});
