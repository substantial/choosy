Pod::Spec.new do |s|
  s.name         = "Choosy"
  s.version      = "0.5.2"
  s.summary      = "Effortlessly enable choosing of apps for external actions like browsing, emailing, tweeting, etc."
  s.homepage     = "http://substantial.github.io/choosy"
  s.source       = { :git => "https://github.com/substantial/choosy.git", :tag => "0.5.2" }

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { "Alex Novosad" => "alexn@substantial.com" }
  s.social_media_url   = "https://twitter.com/choosyios"
  s.description  = <<-DESC
                   An app-agnostic interface for transferring users to other apps, with elegant UI.
                   DESC
  s.screenshots  = [ "https://farm6.staticflickr.com/5321/14140880604_905415ed34_o.png", 
  "https://farm3.staticflickr.com/2917/13953998699_0e885b9b71_o.png", 
  "https://farm6.staticflickr.com/5463/14140880564_4232e87bc8_o.png" ]
  
  s.platform     = :ios, "7.0"

  s.source_files  = "Choosy", "Choosy/**/*.{h,m}", "Choosy/*.{h,m}"
  s.resource_bundle = { "ChoosyResources" => "Choosy/Resources/*" }
  s.requires_arc = true
end
