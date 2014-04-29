Pod::Spec.new do |s|
 s.name = 'Reader'
 s.version = '2.8.0'
 s.license = 'MIT'
 s.summary = 'The open source PDF file reader/viewer for iOS.'
 s.homepage = 'http://www.vfr.org/'
 s.authors = { "Julius Oklamcak" => "joklamcak@gmail.com", "Mark Eissler" => "eissler.m@gmail.com" }
 s.source = { :git => 'https://github.com/markeissler/PDFReader.git', :branch => 'master', :tag => '2.8.0-r3' }
 s.platform = :ios
 s.ios.deployment_target = '5.0'
 s.source_files = 'Sources/**/*.{h,m}'
 s.resources = 'Graphics/Reader-*.png'
 s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'QuartzCore', 'ImageIO', 'MessageUI'
 s.requires_arc = true
end
