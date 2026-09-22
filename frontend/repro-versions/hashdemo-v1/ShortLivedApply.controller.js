sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
  "use strict";
  return Controller.extend("hashdemo.controller.ShortLivedApply", {
    onInit: function () {
      var oViewModel = new JSONModel({ busy: true, message: "" });
      this.getView().setModel(oViewModel, "view");

      // 실제 "조회 중입니다" 팝업과 동일한 흐름: busy=true -> 비동기 조회 -> busy=false
      setTimeout(function () {
        try {
          var ctx = window.HASH_CTX;
          var msg = "신청자 사원번호: " + ctx.empNo.toUpperCase() + " (" + ctx.name + ")";
          oViewModel.setProperty("/message", msg);
        } catch (e) {
          console.error("[hashdemo] ShortLivedApply render failed:", e);
          // 여기서 예외가 나면 아래 setProperty("/busy", false)에 도달하지 못하고
          // busy 인디케이터("조회 중입니다")가 영원히 멈춘 채로 남음 - 실제 스크린샷과 동일
          throw e;
        }
        oViewModel.setProperty("/busy", false);
      }, 800);
    }
  });
});
