import UIKit
import SDWebImageWebPCoder
import Photos
import SDWebImage
import UniformTypeIdentifiers

/// 文件类型枚举，用于统一管理支持的文件类型
enum MediaFileType: String, CaseIterable {
    // 图片类型
    case webp = "org.webmproject.webp"
    case png = "public.png"
    case jpeg = "public.jpeg"
    case gif = "com.compuserve.gif"
    case heic = "public.heic"
    case heif = "public.heif"
    case tiff = "public.tiff"
    case bmp = "com.microsoft.bmp"
    
    // 视频类型
    case mp4 = "public.mpeg-4"
    case mov = "com.apple.quicktime-movie"
    case avi = "public.avi"
    case wmv = "com.microsoft.wmv"
    case mkv = "video/x-matroska"
    
    /// 根据文件扩展名获取对应的文件类型
    /// - Parameter extension: 文件扩展名（不含点）
    /// - Returns: 对应的 MediaFileType，或 nil 如果不支持
    static func fromExtension(_ extension: String) -> MediaFileType? {
        let lowercasedExt = `extension`.lowercased()
        switch lowercasedExt {
        case "webp": return .webp
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        case "gif": return .gif
        case "heic": return .heic
        case "heif": return .heif
        case "tiff", "tif": return .tiff
        case "bmp": return .bmp
        case "mp4": return .mp4
        case "mov": return .mov
        case "avi": return .avi
        case "wmv": return .wmv
        case "mkv": return .mkv
        default: return nil
        }
    }
    
    /// 检查给定的 UTI 类型是否在支持的类型列表中
    /// - Parameter utiType: UTI 类型字符串
    /// - Returns: 是否在支持的类型列表中
    static func isSupportedType(_ utiType: String) -> Bool {
        return MediaFileType.allCases.contains { $0.rawValue == utiType }
    }
}

/// 工具类：下载并保存媒体（图片/视频）到系统相册。
class MediaDownloader {
    
    /// 获取文件的 UTI Type
    /// - Parameters:
    ///   - url: 文件的 URL
    ///   - response: HTTP 响应对象（可选）
    /// - Returns: 文件的 UTI Type 字符串
    static func getUTIType(for url: URL, with response: HTTPURLResponse? = nil) -> String {
        var utiType = MediaFileType.jpeg.rawValue // 使用枚举默认值
        
        // 优先从 HTTP 响应头获取 MIME 类型
        if let response = response,
           let contentType = response.allHeaderFields["Content-Type"] as? String {
            // 使用 UTType API 处理 MIME 类型
            if let type = UTType(mimeType: contentType) {
                let identifiedType = type.identifier
                // 检查识别的类型是否在支持的类型列表中
                if MediaFileType.isSupportedType(identifiedType) {
                    utiType = identifiedType
                } else {
                    // 如果不在支持的类型列表中，使用 URL 后缀判断
                    if let fileType = getFileTypeFromURL(url) {
                        utiType = fileType.rawValue
                    }
                }
            } else {
                // 如果 MIME 类型解析失败，使用 URL 后缀判断
                if let fileType = getFileTypeFromURL(url) {
                    utiType = fileType.rawValue
                }
            }
        } else {
            // 没有响应头，使用 URL 后缀识别文件格式
            if let fileType = getFileTypeFromURL(url) {
                utiType = fileType.rawValue
            }
        }
        
        print("识别到的文件类型: \(utiType)")
        return utiType
    }
    
    /// 从 URL 获取文件类型
    /// - Parameter url: 文件的 URL
    /// - Returns: 对应的 MediaFileType，或 nil 如果不支持
    private static func getFileTypeFromURL(_ url: URL) -> MediaFileType? {
        // 使用 URL 的 pathExtension 属性获取文件扩展名，更可靠
        let pathExtension = url.pathExtension.lowercased()
        return MediaFileType.fromExtension(pathExtension)
    }
    
    /// 从 URL 字符串下载图片并保存到相册。
    /// - Parameters:
    ///   - urlString: 图片的 URL 字符串。
    ///   - completion: 完成回调，返回可选的错误信息。
    static func saveImage(from urlString: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(MediaDownloaderError.invalidURL)
            return
        }
        
        print(url.absoluteString);
        
        // 请求相册访问权限（iOS14+ 支持 limité 模式）
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                break
            case .denied, .restricted, .notDetermined:
                completion(MediaDownloaderError.authorizationDenied)
                return
            @unknown default:
                completion(MediaDownloaderError.authorizationDenied)
                return
            }
            
            // 下载原始图片数据
            URLSession.shared.dataTask(with: url) { data, response, error in
                
                if let error = error {
                    completion(error)
                    return
                }
                guard let data = data, !data.isEmpty else {
                    completion(MediaDownloaderError.invalidImageData)
                    return
                }
                
                // 获取文件类型（UTI Type）
                let utiType = MediaDownloader.getUTIType(for: url, with: response as? HTTPURLResponse)
                
                // 检查是否为 WebP 格式
                if utiType == MediaFileType.webp.rawValue {
                    
                    // 1. 使用 WebP 解码器将 Data 转为 UIImage（支持动画）
                    let image = SDImageWebPCoder.shared.decodedImage(with: data)
                    
                    //将UIImage 转为GIF 格式 iOS相册支持自动播放
                    let gifData = SDImageGIFCoder.shared.encodedData(
                        with: image,
                        format: .GIF,
                        options: nil
                    )
                    
                    if let gifData = gifData{
                        photoPerformChanges(utiType: MediaFileType.gif.rawValue, data: gifData, completion: completion)
                        return
                    }
                    
                    
                }
                
                photoPerformChanges(utiType: utiType, data: data, completion: completion)
                
                
            }.resume()
            
            
        }
    }
    
    
    
    
    static func photoPerformChanges(utiType:String,data:Data, completion: @escaping (Error?) -> Void){
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            // 设置资源类型，确保系统正确识别图片格式
            options.uniformTypeIdentifier = utiType
            creationRequest.addResource(with: .photo, data: data, options: options)
        }) { success, error in
            if !success {
                completion(error ?? MediaDownloaderError.saveFailed)
            } else {
                completion(nil)
            }
        }
    }
    
    
    
    
    /// 从 URL 字符串下载视频并保存到相册。
    /// - Parameters:
    ///   - urlString: 视频的 URL 字符串。
    ///   - completion: 完成回调，返回可选的错误信息。
    static func saveVideo(from urlString: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(MediaDownloaderError.invalidURL)
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                break
            default:
                completion(MediaDownloaderError.authorizationDenied)
                return
            }
            
            // 下载视频到临时文件
            URLSession.shared.downloadTask(with: url) { tempURL, _, error in
                if let error = error {
                    completion(error)
                    return
                }
                guard let tempURL = tempURL else {
                    completion(MediaDownloaderError.invalidVideoData)
                    return
                }
                
                // 将临时文件移到持久目录，以确保 PHAssetResource 能访问
                let fileManager = FileManager.default
                let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                do {
                    try fileManager.moveItem(at: tempURL, to: localURL)
                } catch {
                    completion(error)
                    return
                }
                
                // 保存视频到相册（使用资源请求）
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    creationRequest.addResource(with: .video, fileURL: localURL, options: options)
                }) { success, error in
                    // 删除临时文件
                    try? fileManager.removeItem(at: localURL)
                    if !success {
                        completion(error ?? MediaDownloaderError.saveFailed)
                    } else {
                        completion(nil)
                    }
                }
                
            }.resume()
        }
    }
}

/// 自定义错误类型，用于下载或保存过程中出现的问题。
enum MediaDownloaderError: Error {
    case invalidURL           // 无效的 URL
    case authorizationDenied  // 用户拒绝相册访问
    case invalidImageData     // 无效的图片数据
    case invalidVideoData     // 无效的视频数据
    case saveFailed           // 保存失败
}

/*
 注意：
 1. 请在 Info.plist 中添加下列权限说明，否则会直接拒绝权限：
 - NSPhotoLibraryAddUsageDescription：允许仅添加媒体到相册的描述
 2. iOS14 及以上，使用 `.addOnly` 模式只需添加访问权限，不会获取用户全部相册内容。
 */