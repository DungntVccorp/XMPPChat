Pod::Spec.new do |s|
s.name             = "XMPPChat"
s.version          = "1.0"
s.summary          = "DzLib dungnt Collection liblary XMPPChat Movie DB"
s.homepage         = "https://github.com/DungntVccorp/XMPPChat.git"
s.license          = 'Apache License'
s.author           = { "dung.nt" => "dung.nt.a5901679@gmail.com@gzone.com.vn" }
s.source           = { :git => "https://github.com/DungntVccorp/XMPPChat.git", :tag => s.version.to_s }
s.platform     = :ios, '7.0'
s.requires_arc = true
s.source_files = 'Pod/Classes/XMPPChat/*.{h,m}' , 'Pod/Classes/XMPPChat/XMPPFramework/*.{h,m}' , 'Pod/Classes/XMPPChat/XMPPFramework/**/*.{h,m}' , 'Pod/Classes/XMPPChat/XMPPFramework/Authentication/**/*.{h,m}', 'Pod/Classes/XMPPChat/XMPPFramework/Extensions/**/*.{h,m,xcdatamodel,xcdatamodeld}', 'Pod/Classes/XMPPChat/XMPPFramework/Vendor/**/*.{h,m,a}', 'Pod/Classes/XMPPChat/XMPPFramework/Extensions/XEP-0115/**/*.{h,m,xcdatamodel,xcdatamodeld}', 'Pod/Classes/XMPPChat/XMPPFramework/Extensions/XEP-0136/**/*.{h,m,xcdatamodel,xcdatamodeld}', 'Pod/Classes/XMPPChat/XMPPFramework/Extensions/XEP-0198/**/*.{h,m,xcdatamodel,xcdatamodeld}', 'Pod/Classes/XMPPChat/XMPPFramework/Vendor/CocoaLumberjack/**/*.{h,m}', 'Pod/Classes/XMPPChat/XMPPFramework/Vendor/KissXML/**/*.{h,m}'
s.libraries = 'xml2', 'resolv'
s.xcconfig = {'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2 $(SDKROOT)/usr/include/libresolv' , 'LIBRARY_SEARCH_PATHS' => '$(PODS_ROOT)/XMPPFramework/Vendor/libidn'}
s.vendored_libraries = 'Vendor/libidn/libidn.a'
end