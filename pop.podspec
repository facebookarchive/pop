Pod::Spec.new do |spec|
  spec.name         = 'pop'
  spec.version      = '1.0.11'
  spec.license      =  { :type => 'BSD' }
  spec.homepage     = 'https://github.com/facebook/pop'
  spec.authors      = { 'Kimon Tsinteris' => 'kimon@mac.com' }
  spec.summary      = 'Extensible animation framework for iOS and OS X.'
  spec.source       = { :git => 'https://github.com/facebook/pop.git', :tag => '1.0.10' }
  spec.source_files = 'pop/**/*.{h,m,mm,cpp}'
  spec.public_header_files = 'pop/{POP,POPAnimatableProperty,POPAnimatablePropertyTypes,POPAnimation,POPAnimationEvent,POPAnimationExtras,POPAnimationTracer,POPAnimator,POPBasicAnimation,POPCustomAnimation,POPDecayAnimation,POPDefines,POPGeometry,POPLayerExtras,POPPropertyAnimation,POPSpringAnimation,POPVector}.h'
  spec.requires_arc = true
  spec.social_media_url = 'https://twitter.com/fbOpenSource'
  spec.library = 'c++'
  spec.pod_target_xcconfig = {
       'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
       'CLANG_CXX_LIBRARY' => 'libc++'
  }
  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.8'
  spec.tvos.deployment_target = '9.0'
end
