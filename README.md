# NVMAspects

## About
Yet another AOP library for Objective-C, but implement by using [libffi](https://github.com/libffi/libffi/). The main goal for this lib is to avoid heavily use of `forwardInvocation` and also easy to use.

This lib is inspired by [Aspects](https://github.com/steipete/Aspects), [JSPatch](https://github.com/bang590/JSPatch), [NSBlog](https://www.mikeash.com/pyblog/) and [sunnyxx's blog](sunnyxx), thanks all these people.

## Example

A simple example is look like this.  Currently need the user to care about the memory management when use `invocation` and `arc`,  will add more convenient method on this.  
```
[[UIImage class] nvm_hookInstanceMethod:@selector(imageNamed:)
                             usingBlock:^UIImage *(NVMAspectInfo *info, NSString *name) {
                         	   NSLog(@"Load Image named %@", name);
                                 
                               void *image = nil;
                               [info.oriInvocation invoke];
                               [info.oriInvocation getReturnValue:&image];
                               return (__bridge id)image;
                             }
                                 error:NULL];
```

## Notes

- Actually there are some bugs on lib, see this three issues, [Bit Field](https://github.com/eleme/NVMAspects/issues/3),  [Union](https://github.com/eleme/NVMAspects/issues/2), [Struct contain array](https://github.com/eleme/NVMAspects/issues/1). But `bit field` and `union` also not support by apple's `NSInvocation`，struct contain array is a bug in `libffi`.  All these features used very rare in Objective-C,  so it's not a big problem.

- ## Requirements
See `NVMAspects.podspec` file.

## Installation

add the following line to your Podfile:

```ruby
pod "NVMAspects"
```

## License

NVMAspects is released under the MIT license.
