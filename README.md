# NVMAspects

## About
Yet another AOP library for Objective-C, but implement by using [libffi](https://github.com/libffi/libffi/). The main goal for this lib is to avoid heavily use of `forwardInvocation`, powerful, and easy to use.

This lib is inspired by [Aspects](https://github.com/steipete/Aspects), [JSPatch](https://github.com/bang590/JSPatch), [NSBlog](https://www.mikeash.com/pyblog/) and [sunnyxx's blog](sunnyxx), thanks all these people.

## Example

A simple example is look like this, provide a block to replace the original implementation, look very similar to [Aspects](https://github.com/steipete/Aspects) but have a bit difference. You can alter the arguments or return value by modify `info.invocation`. If you aren't sure the existing of original implementation, you should call `class_addPlaceholderIfNoImplement` fisrt.
```
[[UIImage nvm_hookInstanceMethod:@selector(imageNamed:)
                      usingBlock:^void(NVMAspectInfo *info, NSString *name) {
                        NSLog(@"Load image named %@", name);
                        [info.invocation invoke];
                      }];
```

## Notes

- Actually there are some bugs on this lib, [Bit Field](https://github.com/eleme/NVMAspects/issues/3),  [Union](https://github.com/eleme/NVMAspects/issues/2), [Struct contain array](https://github.com/eleme/NVMAspects/issues/1). But `bit field` and `union` are also not well supportted by apple's `NSInvocation`, struct contain small array is a bug in `libffi`.  All these features used very rare in Objective-C,  so it's not a big problem.

- NVMAspects doesn't forbidden you to hook any method, but if you make some changes to method like `alloc`, you should follow the memory management policy, especially in `ARC`.

- Currently if a class has defined a method, hook this method will change it's `imp`, even if that method is implemented by it's super class. But this is not a big problem, you can distinguish the class by test `[self class]` in you block. If the class has not defined a method, you should call `class_addPlaceholderIfNoImplement` first.

- For problem caused `forwardInvocation`, you can use this keyword to search issues in `Aspects` or `JSPatch`.

## Installation

add the following line to your Podfile:

```ruby
pod "NVMAspects"
```

## License

NVMAspects is released under the MIT license.
