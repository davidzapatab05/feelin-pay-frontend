import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurar notificaciones
    setupNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupNotifications() {
    // Solicitar permisos de notificación
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if granted {
        print("✅ Permisos de notificación concedidos")
      } else {
        print("❌ Permisos de notificación denegados: \(error?.localizedDescription ?? "")")
      }
    }
    
    // Configurar categorías de notificación
    let yapeCategory = UNNotificationCategory(
      identifier: "YAPE_PAYMENT",
      actions: [],
      intentIdentifiers: [],
      options: []
    )
    
    UNUserNotificationCenter.current().setNotificationCategories([yapeCategory])
  }
  
  // Manejar notificaciones cuando la app está en primer plano
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNUserNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Mostrar notificación incluso cuando la app está activa
    completionHandler([.alert, .badge, .sound])
  }
  
  // Manejar toques en notificaciones
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    // Procesar notificación de Yape
    if let yapeData = userInfo["yape_data"] as? [String: Any] {
      handleYapeNotification(yapeData)
    }
    
    completionHandler()
  }
  
  private func handleYapeNotification(_ data: [String: Any]) {
    // Procesar notificación de Yape
    print("📱 Notificación Yape recibida: \(data)")
    
    // Aquí se procesaría la notificación
    // 1. Validar si es real o falsa
    // 2. Extraer datos del pago
    // 3. Enviar a Flutter para procesamiento
  }
}