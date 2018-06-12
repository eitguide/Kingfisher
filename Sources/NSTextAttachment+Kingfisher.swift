//
//  NSTextAttachment+Kingfisher.swift
//  360Live
//
//  Created by Nguyen Nghia on 6/11/18.
//  Copyright © 2018 VNG Corp. All rights reserved.
//

import UIKit
extension NSTextAttachment: KingfisherCompatible { }

extension Kingfisher where Base: NSTextAttachment {
    /**
     Set an image with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     
     If `resource` is `nil`, the `placeholder` image will be set and
     `completionHandler` will be called with both `error` and `image` being `nil`.
     */
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Placeholder? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            setWebURL(nil)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo)
        
        setWebURL(resource.downloadURL)
        
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
        },
            completionHandler: {[weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    
                    guard let strongBase = base, imageURL == self.webURL else {
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }
                    
                    self.setImageTask(nil)
                    guard let image = image else {
                        completionHandler?(nil, error, cacheType, imageURL)
                        return
                    }
                    
                    guard let transitionItem = options.lastMatchIgnoringAssociatedValue(.transition(.none)),
                        case .transition(let transition) = transitionItem, ( options.forceTransition || cacheType == .none) else
                    {
                        strongBase.image = image
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }
                    
                }
        })
        
        setImageTask(task)
        
        return task
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension Kingfisher where Base: NSTextAttachment {
    /// Get the image URL binded to this image view.
    public var webURL: URL? {
        return objc_getAssociatedObject(base, &lastURLKey) as? URL
    }
    
    fileprivate func setWebURL(_ url: URL?) {
        objc_setAssociatedObject(base, &lastURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    
}




