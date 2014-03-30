Pod::Spec.new do |spec|
  spec.name         = 'pop'
  spec.version      = '1.0.0'
  spec.license      =  { :type => 'BSD' }
  spec.homepage     = 'https://github.com/facebook/pop'
  spec.authors      = { 'Kimon Tsinteris' => 'kimon@mac.com' }
  spec.summary      = 'Animation framework for iOS and OS X.'
  spec.source       = { :git => 'https://github.com/facebook/pop.git', :tag => '1.0.0' }
  spec.source_files = 'pop/**/*.{h,m,mm}'
  spec.public_header_files = 'pop/{POP,POPAnimatableProperty,POPAnimation,POPAnimationEvent,POPAnimationExtras,POPAnimationTracer,POPAnimator,POPBasicAnimation,POPCustomAnimation,POPDecayAnimation,POPDefines,POPGeometry,POPPropertyAnimation,POPSpringAnimation}.h'
  spec.requires_arc = true
  spec.social_media_url = 'https://twitter.com/fbOpenSource'

  spec.ios.deployment_target = '6.0'
  spec.osx.deployment_target = '10.7'
end
