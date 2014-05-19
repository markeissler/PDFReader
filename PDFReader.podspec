Pod::Spec.new do |s|
 s.name = 'PDFReader'
 s.version = '3.0.0-b4'
 s.license = 'MIT'
 s.summary = 'The open source PDF file reader/viewer for iOS.'
 s.homepage = 'http://www.vfr.org/'
 s.authors = { "Julius Oklamcak" => "joklamcak@gmail.com", "Mark Eissler" => "mark@mixtur.com" }
 s.source = { :git => 'https://github.com/markeissler/PDFReader.git', :branch => 'develop', :tag => '3.0.0-b4' }
 s.platform = :ios
 s.ios.deployment_target = '5.0'
 s.source_files = 'Sources/**/*.{h,m}'
 s.resources = 'Graphics/Reader-*.png'
 s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'QuartzCore', 'ImageIO', 'MessageUI'
 s.requires_arc = true
end
