Pod::Spec.new do |s|
  s.name		= 'GTWSWBase'
  s.version		= '0.0.1'
  s.summary		= 'OS X Framework for Semantic Web work.'
  s.homepage	= 'https://github.com/kasei/GTWSWBase'
  
  s.license		= { :type => 'BSD', :file => 'LICENSE.md' }
  s.author		= { "Gregory Todd Williams" => "greg@evilfunhouse.com" }
  s.source		= {
  	:git		=> "https://github.com/kasei/GTWSWBase.git",
#  	:tag		=> s.version.to_s
	:commit		=> "46b3f64a"
  }
  
  s.platform		= :osx, '10.9'

  non_arc_files		= 'GTWSWBase/RegexKitLite.m'
  s.requires_arc	= true
  s.source_files	= 'GTWSWBase/*.{h,m}'
  s.exclude_files	= non_arc_files
  spec.private_header_files	= "GTWSWBase/IRI.h"
  s.subspec 'no-arc' do |sna|
  	sna.requires_arc	= false
  	sna.source_files	= non_arc_files
  end
  
  spec.frameworks	= 'Foundation'
  spec.libraries	= 'libicucore'
end
