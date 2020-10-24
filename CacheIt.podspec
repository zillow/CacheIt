Pod::Spec.new do |spec|
  spec.name             = "CacheIt"
  spec.version          = "1.0.4"
  spec.summary          = "Easy to use caching library"
  spec.description      = "Easy to use caching library"

  spec.homepage         = "https://gitlab.zgtools.net/itx/zillow-docs/cacheket"
  spec.license          = "Private"
  spec.author           = { "Brett Hamlin" => "bhamlin@zillowgroup.com", 
			   "Amy Tsao" => "amytis@zillowgroup.com"  }
  spec.platform         = :ios, "10.0"
  spec.source = { :git => '' }
  spec.source_files     = "Sources/CacheIt/**/*.{h,m,swift}"
  spec.swift_version    = "5" 
end
