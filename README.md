# MediaDownloader

MediaDownloader 是一个 Swift 工具类，用于从 URL 下载媒体文件（图片和视频）并保存到系统相册。

## 功能特点

- 支持多种图片格式：webp、png、jpeg、gif、heic、heif、tiff、bmp
- 支持多种视频格式：mp4、mov、avi、wmv、mkv
- 自动识别文件类型（通过 URL 后缀或 HTTP 响应头）
- 特别处理 WebP 格式，将其转换为 GIF 以便在 iOS 相册中自动播放
- 支持 iOS 14+ 的 `.addOnly` 权限模式，保护用户隐私
- 提供完整的错误处理机制

## 依赖库

- [SDWebImage](https://github.com/SDWebImage/SDWebImage) - 用于图片处理
- [SDWebImageWebPCoder](https://github.com/SDWebImage/SDWebImageWebPCoder) - 用于 WebP 格式支持
- Photos - 系统框架，用于保存媒体到相册
- UniformTypeIdentifiers - 系统框架，用于处理文件类型

## 安装

1. 使用 CocoaPods 安装依赖：

```ruby
pod 'SDWebImage'
pod 'SDWebImageWebPCoder'
```

2. 将 `MediaDownloader.swift` 文件添加到你的项目中

3. 在 `Info.plist` 中添加相册访问权限说明：

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>允许应用将媒体保存到相册</string>
```

## 使用方法

### 保存图片

```swift
MediaDownloader.saveImage(from: "https://example.com/image.jpg") { error in
    if let error = error {
        print("保存失败: \(error)")
    } else {
        print("保存成功")
    }
}
```

### 保存视频

```swift
MediaDownloader.saveVideo(from: "https://example.com/video.mp4") { error in
    if let error = error {
        print("保存失败: \(error)")
    } else {
        print("保存成功")
    }
}
```

## 支持的文件类型

### 图片类型
- webp
- png
- jpeg (jpg)
- gif
- heic
- heif
- tiff (tif)
- bmp

### 视频类型
- mp4
- mov
- avi
- wmv
- mkv

## 注意事项

1. 请确保在 `Info.plist` 中添加了 `NSPhotoLibraryAddUsageDescription` 权限说明，否则应用会直接拒绝权限
2. iOS 14 及以上版本使用 `.addOnly` 模式，只需添加访问权限，不会获取用户全部相册内容
3. WebP 格式会被转换为 GIF 格式，以便在 iOS 相册中自动播放
4. 保存视频时，会先下载到临时文件，然后再保存到相册

## 错误处理

`MediaDownloader` 提供了以下错误类型：

- `invalidURL` - 无效的 URL
- `authorizationDenied` - 用户拒绝相册访问
- `invalidImageData` - 无效的图片数据
- `invalidVideoData` - 无效的视频数据
- `saveFailed` - 保存失败

## 系统要求

- iOS 14.0+
- Swift 5.0+

## 许可证

MIT
