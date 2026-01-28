Pod::Spec.new do |s|
  s.name        = 'bridge'
  s.module_name = 'Bridge'
  s.version     = '0.0.1'
  s.summary     = 'Rust bridge'
  s.description = 'Rust bridge for Flutter'
  s.homepage    = 'https://example.com'
  s.license     = { :type => 'MIT' }
  s.author      = { 'Sharmila' => 'sharmila@example.com' }

  s.source      = { :git => 'https://example.com/bridge.git', :tag => s.version.to_s }
  s.platform    = :ios, '15.0'

  s.source_files = []
  s.vendored_frameworks = 'ios/bridge/Bridge.xcframework'
end
