# NVMAspects

## About

## Example

## Notes

- original invocation 返回 id 类型的情况，需要像下面的示例一样直接操作内存，不要让 arc 介入，否则会崩
    ```
    [self nvm_hookClassMethod:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)
                   usingBlock:^UIImage *(NVMAspectInfo *info, NSString *name, NSBundle *bundle, UITraitCollection *traitCollection) {
                     void *image = nil;
                     [info.oriInvocation invoke];
                     [info.oriInvocation getReturnValue:&image];
                     if (image) {
                       objc_setAssociatedObject((__bridge id)image, @selector(nvm_imageName), name, OBJC_ASSOCIATION_COPY_NONATOMIC);
                     }
                     return (__bridge id)image;
                   }
                        error:NULL];
    ```

## Requirements
See `NVMAspects.podspec` file.

## Installation

NVMAspects is available through our private [pod source](git@git.elenet.me:eleme.mobile.ios/ios-specs.git). To install
it:

1. add the following line to the beginning of your Podfile:

```ruby
source 'git@git.elenet.me:eleme.mobile.ios/ios-specs.git'
```

2. add the following line to your Podfile:

```ruby
pod "NVMAspects"
```


## Author

Karl Peng, codelife2012@gmail.com

## License

NVMAspects is created and licensed by Rajax Network Technology Co., Ltd. Copyright 2017 Rajax Network Technology Co., Ltd. All rights reserved.
