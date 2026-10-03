/* I'm PINCH — landing-page helper (カスタムJS > 下部の本文JS).
   Runs on the landing page, not inside the chat iframe.
   Seeded from cb_backend/db/seeds/im_pinch/lp.js by lexica_sample.rb. */
(function () {
  var frame = document.getElementById('previewSdk');
  if (!frame || document.getElementById('pinch-open-banner')) return;

  var isOpen = function () { return frame.getBoundingClientRect().height >= 120; };
  var openChat = function () {
    frame.contentWindow.postMessage({ action: 'openPreview', actionData: 'none' }, '*');
  };

  // The launcher is hidden by the scenario CSS (it relies on :has()), so the small closed
  // iframe must not swallow taps on the page underneath it.
  var launcherHidden = !!(window.CSS && CSS.supports && CSS.supports('selector(:has(*))'));

  // Pages without their own ".bot_open" button get a floating one, like the banner on the original LP.
  var banner = null;
  var placeBanner = function () {
    // sit above a fixed bar the page may already have at the bottom
    var offset = 12;
    banner.style.visibility = 'hidden';
    var el = document.elementFromPoint(window.innerWidth / 2, window.innerHeight - 4);
    banner.style.visibility = '';
    for (; el && el !== document.body && el !== document.documentElement; el = el.parentElement) {
      if (getComputedStyle(el).position === 'fixed') {
        offset = window.innerHeight - el.getBoundingClientRect().top + 12;
        break;
      }
    }
    banner.style.bottom = offset + 'px';
  };
  if (!document.querySelector('.bot_open')) {
    var style = document.createElement('style');
    style.textContent =
      '#pinch-open-banner{position:fixed;left:50%;bottom:12px;z-index:1000;width:min(80vw,360px);height:64px;' +
      'padding:0 20px;border:0;border-radius:32px;background:#333;color:#fff;font:700 16px/64px "Hiragino Sans",' +
      'Meiryo,sans-serif;letter-spacing:1px;text-align:center;cursor:pointer;box-shadow:0 6px 18px rgba(0,0,0,.25);' +
      'transform:translateX(-50%);animation:pinchOpenBanner .8s ease infinite alternate}' +
      '#pinch-open-banner:hover{opacity:.8}' +
      '#pinch-open-banner[hidden]{display:none}' +
      '@keyframes pinchOpenBanner{from{transform:translateX(-50%) scale(.94)}to{transform:translateX(-50%) scale(1)}}';
    document.head.appendChild(style);

    banner = document.createElement('button');
    banner.id = 'pinch-open-banner';
    banner.type = 'button';
    banner.textContent = '今すぐお得に試してみる ›';
    banner.addEventListener('click', openChat);
    document.body.appendChild(banner);
    placeBanner();
    window.addEventListener('resize', placeBanner);
  }

  var sync = function () {
    var open = isOpen();
    if (launcherHidden) {
      var value = open ? 'auto' : 'none';
      if (frame.style.pointerEvents !== value) frame.style.pointerEvents = value;
    }
    if (banner) banner.hidden = open;
  };
  new MutationObserver(sync).observe(frame, { attributes: true, attributeFilter: ['style', 'width', 'height'] });
  sync();
})();
