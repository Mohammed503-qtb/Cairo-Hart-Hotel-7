export const dynamic = 'force-dynamic'

export default function Page() {
  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: `
        html, body { margin: 0 !important; padding: 0 !important; height: 100%; background: #FAF7F2; overflow: hidden; }
        #flutter-frame { position: fixed; inset: 0; width: 100%; height: 100%; border: 0; display: block; }
        #loader {
          position: fixed; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center;
          background: #FAF7F2; color: #1A1A1A; font-family: -apple-system, 'Segoe UI', Tahoma, sans-serif; z-index: 10;
          transition: opacity .4s ease;
        }
        #loader.hide { opacity: 0; pointer-events: none; }
        .logo { width: 56px; height: 56px; border-radius: 14px; background: #B8975A; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 28px; font-weight: 700; margin-bottom: 18px; box-shadow: 0 8px 24px rgba(184,151,90,.3); }
        .title { font-size: 17px; font-weight: 700; margin-bottom: 4px; }
        .subtitle { font-size: 13px; color: #6B6357; margin-bottom: 22px; }
        .spinner { width: 28px; height: 28px; border: 2.5px solid rgba(184,151,90,.2); border-top-color: #B8975A; border-radius: 50%; animation: spin 1s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }
      `}} />
      <div id="loader">
        <div className="logo">ق</div>
        <div className="title">فندق قلب القاهرة</div>
        <div className="subtitle">جارٍ تحميل المنصة…</div>
        <div className="spinner"></div>
      </div>
      <iframe id="flutter-frame" src="/flutter-static/index.html" title="Cairo Heart Hotel" allow="clipboard-write; clipboard-read; fullscreen" />
      <script dangerouslySetInnerHTML={{ __html: `
        const frame = document.getElementById('flutter-frame');
        const loader = document.getElementById('loader');
        let hidden = false;
        function hideLoader() {
          if (hidden) return; hidden = true;
          setTimeout(() => loader.classList.add('hide'), 600);
        }
        frame.addEventListener('load', () => { setTimeout(hideLoader, 1500); });
        setTimeout(hideLoader, 10000);
      `}} />
    </>
  )
}
