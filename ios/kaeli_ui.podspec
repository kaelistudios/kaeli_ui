# kaeli_ui con CocoaPods (KaeliBadge, 0.10.0). Las apps con Swift Package Manager usan ios/kaeli_ui/Package.swift.
Pod::Spec.new do |s|
  s.name             = 'kaeli_ui'
  s.version          = '0.10.0'
  s.summary          = 'Paquete compartido de las apps de Kaeli (número del ícono).'
  s.description      = 'KaeliBadge: número del ícono y notificaciones ya vistas.'
  s.homepage         = 'https://github.com/kaelistudios/kaeli_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kaeli' => 'soporte@kaeliapps.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'kaeli_ui/Sources/kaeli_ui/**/*.swift'
  s.resource_bundles = { 'kaeli_ui_privacy' => ['kaeli_ui/Sources/kaeli_ui/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
