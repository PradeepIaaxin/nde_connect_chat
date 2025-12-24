Pod::Spec.new do |s|
  s.name             = 'bridge'
  s.version          = '0.0.1'
  s.summary          = 'Rust static library for Flutter'
  s.description      = 'Rust bindings generated via flutter_rust_bridge'
  s.homepage         = 'https://example.com/bridge'
  s.license          = { :type => 'MIT', :text => 'MIT License' }
  s.authors          = { 'Sharmila' => 'sharmila@example.com' }

  s.source           = { :path => '.' }
  s.platform         = :ios, '13.0'
  s.static_framework = true

  # Rust only
  s.source_files = []

  # Static library produced by cargo
  s.vendored_libraries = 'libbridge.a'

  # 🔥🔥🔥 THIS IS THE KEY FIX 🔥🔥🔥
  # Force-load into the *Runner binary*
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-Wl,-force_load,${PODS_TARGET_SRCROOT}/libbridge.a'
  }

  s.script_phase = {
    :name => 'Build Rust bridge',
    :execution_position => :before_compile,
    :script => <<-SCRIPT
      set -e
      export PATH="$HOME/.cargo/bin:$PATH"
      cd "${PODS_TARGET_SRCROOT}"

      if [[ "$PLATFORM_NAME" == "iphonesimulator" ]]; then
        cargo build --release --target aarch64-apple-ios-sim
        cp target/aarch64-apple-ios-sim/release/libbridge.a libbridge.a
      else
        cargo build --release --target aarch64-apple-ios
        cp target/aarch64-apple-ios/release/libbridge.a libbridge.a
      fi
    SCRIPT
  }
end
