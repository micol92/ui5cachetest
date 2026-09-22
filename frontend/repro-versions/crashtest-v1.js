(function () {
  try {
    var ctx = window.CRASH_CTX;
    var html =
      '<p>사원번호: ' + ctx.empNo.toUpperCase() + '</p>' +
      '<p>이름: ' + ctx.name + '</p>' +
      '<p style="color:#888">crashtest.js 버전: v1</p>';
    document.getElementById('content').innerHTML = html;
  } catch (e) {
    console.error('[crashtest v1] render failed:', e);
    document.getElementById('content').innerHTML = '';
    throw e;
  }
})();
