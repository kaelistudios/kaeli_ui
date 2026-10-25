package com.kaeli.kaeli_ui;

import android.app.NotificationManager;
import android.content.Context;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Canal «kaeli_ui/badge» (0.10.0, KaeliBadge en lib/src/badge.dart). En Android el número o el punto del ícono lo pone
 * el lanzador según las notificaciones que siguen en la barra: al abrir la app (o con 0 sin leer) se quitan de la barra.
 * En Java, para no depender de la versión de Kotlin de cada app.
 */
public class KaeliUiPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private MethodChannel channel;
  private Context context;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    context = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), "kaeli_ui/badge");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
    context = null;
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result result) {
    switch (call.method) {
      case "clearDelivered":
        clear();
        result.success(null);
        break;
      case "set":
        Integer count = call.argument("count");
        if (count == null || count <= 0) clear();
        result.success(null);
        break;
      default:
        result.notImplemented();
    }
  }

  private void clear() {
    if (context == null) return;
    NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
    if (manager != null) manager.cancelAll();
  }
}
