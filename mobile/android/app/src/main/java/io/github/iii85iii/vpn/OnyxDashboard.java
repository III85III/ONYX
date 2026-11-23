package io.github.iii85iii.vpn;

import android.app.Activity;
import android.graphics.Color;
import android.net.Uri;
import android.webkit.WebMessage;
import android.webkit.WebMessagePort;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import org.json.JSONObject;

/** The same bundled dashboard as Windows. Only the local top-level page receives a port. */
final class OnyxDashboard extends WebView {
    private static final String ORIGIN = "https://appassets.androidplatform.net";
    interface Host {
        void onReady();
        void onAction(String action);
    }
    private WebMessagePort port;
    private String previous;

    OnyxDashboard(Activity activity, Host host) {
        super(activity);
        setBackgroundColor(Color.rgb(6, 7, 10));
        getSettings().setJavaScriptEnabled(true);
        getSettings().setAllowFileAccess(false);
        getSettings().setAllowContentAccess(false);
        // WebView must load the HTTPS asset origin. The client below serves
        // only bundled files and returns a synthetic 404 for all other URLs.
        getSettings().setBlockNetworkLoads(false);
        setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return true;
            }
            @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                String url = request.getUrl().toString();
                for (String file : new String[]{"index.html", "tailwind.css", "icon.png"}) {
                    if (!url.equals(ORIGIN + "/" + file)) continue;
                    String mime = file.endsWith(".html") ? "text/html" : file.endsWith(".css") ? "text/css" : "image/png";
                    try { return new WebResourceResponse(mime, file.endsWith(".png") ? null : "UTF-8", activity.getAssets().open(file)); }
                    catch (IOException ignored) { break; }
                }
                return new WebResourceResponse("text/plain", "UTF-8", 404, "Not Found", null, new ByteArrayInputStream(new byte[0]));
            }
            @Override public void onPageFinished(WebView view, String url) {
                if (!url.equals(ORIGIN + "/index.html") || activity.isDestroyed()) return;
                if (port != null) port.close();
                WebMessagePort[] pair = createWebMessageChannel();
                port = pair[0];
                port.setWebMessageCallback(new WebMessagePort.WebMessageCallback() {
                    @Override public void onMessage(WebMessagePort channel, WebMessage message) {
                        if (activity.isDestroyed() || channel != port) return;
                        String action = message.getData();
                        if ("READY".equals(action)) { previous = null; host.onReady(); }
                        else if (isShown() && action != null) host.onAction(action);
                    }
                });
                postWebMessage(new WebMessage("ONYX", new WebMessagePort[]{pair[1]}), Uri.parse(ORIGIN));
            }
        });
        loadUrl(ORIGIN + "/index.html");
    }

    void render(JSONObject state) {
        String json = state.toString();
        if (port != null && !json.equals(previous)) {
            port.postMessage(new WebMessage(json));
            previous = json;
        }
    }
    @Override public void destroy() {
        if (port != null) { port.close(); port = null; }
        super.destroy();
    }
}
