package httpserver

import "html/template"

// inviteTemplate is the page an invitation link opens in a browser. It is the
// first thing a new user sees, so it states plainly who invited them, whether
// the link still works, and both ways in: the app if it is installed, the web
// app otherwise.
var inviteTemplate = template.Must(template.New("invite").Parse(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{if .InviterName}}{{.InviterName}} invited you to {{.AppName}}{{else}}{{.AppName}} invitation{{end}}</title>
<meta property="og:title" content="{{if .InviterName}}{{.InviterName}} invited you to {{.AppName}}{{else}}Join {{.AppName}}{{end}}">
<style>
  :root {
    --bg: #f0f2f5;
    --card: #ffffff;
    --text: #050505;
    --muted: #65676b;
    --accent: #0084ff;
    --danger: #d93025;
  }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #18191a; --card: #242526; --text: #e4e6eb; --muted: #b0b3b8; }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; display: grid; place-items: center;
    background: var(--bg); color: var(--text);
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    padding: 24px;
  }
  .card {
    width: 100%; max-width: 420px; background: var(--card);
    border-radius: 16px; padding: 32px 24px; text-align: center;
    box-shadow: 0 1px 2px rgba(0,0,0,.1), 0 8px 24px rgba(0,0,0,.08);
  }
  .brand { font-size: 13px; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); }
  h1 { font-size: 22px; margin: 16px 0 4px; line-height: 1.3; }
  .handle { color: var(--muted); margin: 0 0 24px; font-size: 15px; }
  .avatar {
    width: 96px; height: 96px; border-radius: 50%; margin: 20px auto 0;
    display: grid; place-items: center; overflow: hidden;
    background: var(--accent); color: #fff; font-size: 38px; font-weight: 600;
  }
  .avatar img { width: 100%; height: 100%; object-fit: cover; }
  .notice { background: var(--bg); border-radius: 12px; padding: 14px 16px; color: var(--muted); font-size: 14px; margin: 8px 0 20px; }
  .notice.error { color: var(--danger); }
  .btn {
    display: block; width: 100%; padding: 14px 18px; margin: 10px 0;
    border-radius: 10px; border: none; font-size: 16px; font-weight: 600;
    text-decoration: none; cursor: pointer;
  }
  .btn.primary { background: var(--accent); color: #fff; }
  .btn.secondary { background: var(--bg); color: var(--text); }
  .code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; letter-spacing: .16em; font-size: 15px; }
  footer { margin-top: 20px; font-size: 12px; color: var(--muted); }
</style>
</head>
<body>
  <main class="card">
    <div class="brand">{{.AppName}}</div>

    {{if .Valid}}
      <div class="avatar">
        {{if .AvatarURL}}<img src="{{.AvatarURL}}" alt="">{{else}}{{slice .InviterName 0 1}}{{end}}
      </div>
      <h1>{{.InviterName}} invited you</h1>
      <p class="handle">{{.InviterUser}}</p>
      {{if .UsesText}}<div class="notice">{{.UsesText}}{{if .ExpiresText}} Expires {{.ExpiresText}}.{{end}}</div>{{end}}

      <a class="btn primary" href="{{.DeepLink}}">Open in the app</a>
      <a class="btn secondary" href="/?invite={{.Code}}">Continue in the browser</a>
      <footer>Invite code <span class="code">{{.Code}}</span></footer>
    {{else}}
      <h1>Invitation not available</h1>
      <div class="notice error">{{.Reason}}</div>
      <a class="btn secondary" href="/">Go to {{.AppName}}</a>
      {{if .Code}}<footer>Code <span class="code">{{.Code}}</span></footer>{{end}}
    {{end}}
  </main>
</body>
</html>
`))
