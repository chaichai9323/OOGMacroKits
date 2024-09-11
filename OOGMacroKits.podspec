Pod::Spec.new do |s|
  s.name         = "OOGMacroKits"
  s.version      = "1.0.0"
  s.summary      = "对各种常用库的使用宏封装"
  s.homepage     = "https://github.com/chaichai9323/OOGMacroKits"
  s.license      = "MIT"
  s.author       = { "chaichai9323" => "chailintao@laien.io" }
  s.platform     = :ios, "14.0"
  s.source       = { :git => 'https://github.com/chaichai9323/OOGMacroKits.git', :tag => "#{s.version}" }

  s.static_framework = true
  s.swift_version = '5.9'
  
  s.preserve_paths = 'Package.swift', 'Sources'
  s.source_files = "Sources/OOGMacroKits/Test.swift"
    
  script = <<-SCRIPT
  env -i PATH="$PATH" "$SHELL" -l -c "swift build -v -c release --package-path $PODS_TARGET_SRCROOT --scratch-path $PODS_ROOT/#{s.name}/Macro"
  SCRIPT
  
  s.script_phase = {
    :name => 'Build OOGMacros plugin',
    :script => script,
    :execution_position => :before_compile
  }
  
  s.xcconfig = {
    'OTHER_SWIFT_FLAGS' => "-load-plugin-executable $(PODS_ROOT)/#{s.name}/Macro/release/OOGMacros#OOGMacros"
  }
  
end
