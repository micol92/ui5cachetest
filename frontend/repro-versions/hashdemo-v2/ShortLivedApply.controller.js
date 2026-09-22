sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
  "use strict";
  return Controller.extend("hashdemo.controller.ShortLivedApply", {
    onInit: function () {
      var oViewModel = new JSONModel({ busy: true, message: "" });
      this.getView().setModel(oViewModel, "view");

      setTimeout(function () {
        try {
          var ctx = window.HASH_CTX;
          // v2: employeeNumber 필드를 읽도록 컨트롤러도 함께 변경됨 (정상적인 배포)
          var msg = "신청자 사번: " + ctx.employeeNumber.toUpperCase() + " (" + ctx.name + ") - v2";
          oViewModel.setProperty("/message", msg);
        } catch (e) {
          console.error("[hashdemo] ShortLivedApply render failed:", e);
          throw e;
        }
        oViewModel.setProperty("/busy", false);
      }, 800);
    }
  });
});
