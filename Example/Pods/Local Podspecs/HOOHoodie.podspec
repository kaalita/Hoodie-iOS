Pod::Spec.new do |s|
  s.name             = "HOOHoodie"
  s.version          = "0.2.2"
  s.summary          = "Hoodie for iOS"
  s.description      = <<-DESC
                       Using the Hoodie API for the backend and Couchbase Lite as local data storage, 
                       Hoodie makes it fast and easy to develop offline first apps.
                       DESC
  s.homepage         = "http://hood.ie"
  s.license          = 'Apache 2.0'
  s.author           = { "Katrin Apel" => "katrin.apel@gmail.com" }
  s.source           = { :git => "https://github.com/kaalita/Hoodie-iOS.git", :tag => "0.2.2" }
  s.social_media_url = 'https://twitter.com/hoodiehq'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  s.source_files = 'Classes/ios/*.{h,m}'
  s.ios.vendored_frameworks = 'Frameworks/CouchbaseLite.framework'
  s.xcconfig = { "OTHER_LDFLAGS" => "-weak_library /usr/lib/libz.dylib" }
  s.dependency 'AFNetworking', '~> 2.0'
  s.dependency 'FMDB', '~> 2.3'
end