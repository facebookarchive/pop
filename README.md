![pop](https://github.com/facebook/pop/blob/master/Images/pop.gif?raw=true)

Pop is an extensible animation engine for iOS, tvOS, and OS X. In addition to basic static animations, it supports spring and decay dynamic animations, making it useful for building realistic, physics-based interactions. The API allows quick integration with existing Objective-C codebases and enables the animation of any property on any object. It's a mature and well-tested framework that drives all the animations and transitions in [Paper](http://www.facebook.com/paper).

[![Build Status](https://travis-ci.org/facebook/pop.svg)](https://travis-ci.org/facebook/pop)

## Installation

Pop is available on [CocoaPods](http://cocoapods.org). Just add the following to your project Podfile:

```ruby
pod 'pop', '~> 1.0'
```

Bugs are first fixed in master and then made available via a designated release. If you tend to live on the bleeding edge, you can use Pop from master with the following Podfile entry:

```ruby
pod 'pop', :git => 'https://github.com/facebook/pop.git'
```

### Framework (manual)
By adding the project to your project and adding pop.embedded framework to the Embedded Binaries section on the General tab of your app's target, you can set up pop in seconds! This also enables `@import pop` syntax with header modules.

**Note**: because of some awkward limitations with Xcode, embedded binaries must share the same name as the module and must have `.framework` as an extension. This means that you'll see three pop.frameworks when adding embedded binaries (one for OS X, one for tvOS, and one for iOS). You'll need to be sure to add the right one; they appear identically in the list but note the list is populated in order of targets. You can verify the correct one was chosen by checking the path next to the framework listed, in the format `<configuration>-<platform>` (e.g. `Debug-iphoneos`).

![Embedded Binaries](Images/EmbeddedBinaries.png?raw=true)

**Note 2**: this method does not currently play nicely with workspaces. Since targets can only depend on and embed products from other targets in the same project, it only works when pop.xcodeproj is added as a subproject to the current target's project. Otherwise, you'll need to manually set the build ordering in the scheme and copy in the product.

### Static Library (manual)
Alternatively, you can add the project to your workspace and adopt the provided configuration files or manually copy the files under the pop subdirectory into your project. If installing manually, ensure the C++ standard library is also linked by including `-lc++` to your project linker flags.

## Usage

Pop adopts the Core Animation explicit animation programming model. Use by including the following import:

```objective-c
#import <pop/POP.h>
```

or if you're using the embedded framework:

```objective-c
@import pop;
```

### Start, Stop & Update

To start an animation, add it to the object you wish to animate:

```objective-c
POPSpringAnimation *anim = [POPSpringAnimation animation];
...
[layer pop_addAnimation:anim forKey:@"myKey"];
```

To stop an animation, remove it from the object referencing the key specified on start:

```objective-c
[layer pop_removeAnimationForKey:@"myKey"];
```

The key can also be used to query for the existence of an animation. Updating the toValue of a running animation can provide the most seamless way to change course:

```objective-c
anim = [layer pop_animationForKey:@"myKey"];
if (anim) {
  /* update to value to new destination */
  anim.toValue = @(42.0);
} else {
  /* create and start a new animation */
  ....
}
```

While a layer was used in the above examples, the Pop interface is implemented as a category addition on NSObject. Any NSObject or subclass can be animated.

### Types

There are four concrete animation types: spring, decay, basic and custom.

Spring animations can be used to give objects a delightful bounce. In this example, we use a spring animation to animate a layer's bounds from its current value to (0, 0, 400, 400):

```objective-c
POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
anim.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 400, 400)];
[layer pop_addAnimation:anim forKey:@"size"];
```
Decay animations can be used to gradually slow an object to a halt. In this example, we decay a layer's positionX from it's current value and velocity 1000pts per second:

```objective-c
POPDecayAnimation *anim = [POPDecayAnimation animationWithPropertyNamed:kPOPLayerPositionX];
anim.velocity = @(1000.);
[layer pop_addAnimation:anim forKey:@"slide"];
```

Basic animations can be used to interpolate values over a specified time period. To use an ease-in ease-out animation to animate a view's alpha from 0.0 to 1.0 over the default duration:
```objective-c
POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
anim.fromValue = @(0.0);
anim.toValue = @(1.0);
[view pop_addAnimation:anim forKey:@"fade"];
```
`POPCustomAnimation` makes creating custom animations and transitions easier by handling CADisplayLink and associated time-step management. See header for more details.


### Properties

The property animated is specified by the `POPAnimatableProperty` class. In this example we create a spring animation and explicitly set the animatable property corresponding to `-[CALayer bounds]`:

```objective-c
POPSpringAnimation *anim = [POPSpringAnimation animation];
anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
```

The framework provides many common layer and view animatable properties out of box. You can animate a custom property by creating a new instance of the class. In this example, we declare a custom volume property:

```objective-c
prop = [POPAnimatableProperty propertyWithName:@"com.foo.radio.volume" initializer:^(POPMutableAnimatableProperty *prop) {
  // read value
  prop.readBlock = ^(id obj, CGFloat values[]) {
    values[0] = [obj volume];
  };
  // write value
  prop.writeBlock = ^(id obj, const CGFloat values[]) {
    [obj setVolume:values[0]];
  };
  // dynamics threshold
  prop.threshold = 0.01;
}];

anim.property = prop;
```

For a complete listing of provided animatable properties, as well more information on declaring custom properties see `POPAnimatableProperty.h`.


### Debugging

Here are a few tips when debugging. Pop obeys the Simulator's Toggle Slow Animations setting. Try enabling it to slow down animations and more easily observe interactions.

Consider naming your animations. This will allow you to more easily identify them when referencing them, either via logging or in the debugger:

```objective-c
anim.name = @"springOpen";
```

Each animation comes with an associated tracer. The tracer allows you to record all animation-related events, in a fast and efficient manner, allowing you to query and analyze them after animation completion. The below example starts the tracer and configures it to log all events on animation completion:

```objective-c
POPAnimationTracer *tracer = anim.tracer;
tracer.shouldLogAndResetOnCompletion = YES;
[tracer start];
```

See `POPAnimationTracer.h` for more details.

## Testing

Pop has extensive unit test coverage. To install test dependencies, navigate to the root pop directory and type:

```sh
pod install
```

Assuming CocoaPods is installed, this will include the necessary OCMock dependency to the unit test targets.

## SceneKit

Due to SceneKit requiring iOS 8 and OS X 10.9, POP's SceneKit extensions aren't provided out of box. Unfortunately, [weakly linked frameworks](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/WeakLinking.html) cannot be used due to issues mentioned in the [Xcode 6.1 Release Notes](https://developer.apple.com/library/ios/releasenotes/DeveloperTools/RN-Xcode/Chapters/xc6_release_notes.html).

To remedy this, you can easily opt-in to use SceneKit! Simply add this to the Preprocessor Macros section of your Xcode Project:

```
POP_USE_SCENEKIT=1
```

## Resources

A collection of links to external resources that may prove valuable:

* [AGGeometryKit+POP - Animating Quadrilaterals with Pop](https://github.com/hfossli/aggeometrykit-pop)
* [Apple – Core Animation Programming Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html)
* [iOS Development Tips – UIScrollView-like deceleration with Pop](http://iosdevtips.co/post/84571595353/replicating-uiscrollviews-deceleration-with-facebook)
* [Pop Playground – Repository of Pop animation examples](https://github.com/callmeed/pop-playground)
* [Pop Playground 2 – Playing with Facebook's framework](http://victorbaro.com/2014/05/pop-playground-playing-with-facebooks-framework/)
* [POP-MCAnimate – Concise syntax for the Pop animation framework](https://github.com/matthewcheok/POP-MCAnimate)
* [Popping - Great examples in one project](https://github.com/schneiderandre/popping)
* [Rebound – Spring Animations for Android](http://facebook.github.io/rebound/)
* [Tapity Tutorial – Getting Started with Pop](http://tapity.com/tutorial-getting-started-with-pop/)
* [Tweaks – Easily adjust parameters for iOS apps in development](https://github.com/facebook/tweaks)
* [POP Tutorial in 5 steps](https://github.com/maxmyers/FacebookPop)
* [VBFPopFlatButton – Flat animatable button, using Pop to transition between states](https://github.com/victorBaro/VBFPopFlatButton)

## Contributing
See the CONTRIBUTING file for how to help out.

## License

Pop is released under a BSD License. See LICENSE file for details.
