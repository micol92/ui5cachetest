sap.ui.define(["sap/ui/core/mvc/Controller"], function (Controller) {
  "use strict";
  // 이 메뉴는 window.HASH_CTX(셸이 주는 값)를 참조하지 않으므로, 필드명이 바뀌어도 영향받지 않음
  // (실제 스크린샷에서 CarRegistration은 정상 동작했던 것과 동일한 패턴)
  return Controller.extend("hashdemo.controller.CarRegistration", {
    onInit: function () {
      console.log("[hashdemo] CarRegistration loaded OK");
    }
  });
});
