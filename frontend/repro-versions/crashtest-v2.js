(function () {
  try {
    var ctx = window.CRASH_CTX;
    var html =
      '<p>사번: ' + ctx.employeeNumber.toUpperCase() + '</p>' +
      '<p>이름: ' + ctx.name + '</p>' +
      '<p style="color:#888">crashtest.js 버전: v2 (신규 배포)</p>';
    document.getElementById('content').innerHTML = html;
  } catch (e) {
    console.error('[crashtest v2] render failed:', e);
    document.getElementById('content').innerHTML = '';
    throw e;
  }
})();
