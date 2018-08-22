# AssetChecker

在Xcode工程的Build Phases中增加Run Script:

```
${SRCROOT}/shell/bin/AssetChecker ${SRCROOT}/Class ${SRCROOT}/Class/Images.xcassets "[]"

```

说明AssetChecker需要传入四个参数，源码路径，Images.xcassets路径，想要忽略检查的图片asset白名单名称数组。
