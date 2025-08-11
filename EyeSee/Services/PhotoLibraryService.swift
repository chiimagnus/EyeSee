//
//  PhotoLibraryService.swift
//  EyeSee
//
//  Created by chiimagnus on 2025/8/11.
//

import Foundation
import Photos
import Combine
import UIKit

final class PhotoLibraryService {
    enum PhotoLibraryError: Error, LocalizedError {
        case notAuthorized
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized: return "没有相册添加权限"
            case .saveFailed: return "保存到相册失败"
            }
        }
    }

    func requestAddOnlyAuthorization() -> AnyPublisher<Bool, Never> {
        Future<Bool, Never> { promise in
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .authorized {
                promise(.success(true))
                return
            }
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    promise(.success(newStatus == .authorized))
                }
            } else {
                promise(.success(false))
            }
        }
        .eraseToAnyPublisher()
    }

    func saveImageToLibrary(_ image: UIImage) -> AnyPublisher<Void, Error> {
        requestAddOnlyAuthorization()
            .flatMap { granted -> AnyPublisher<Void, Error> in
                guard granted else {
                    return Fail(error: PhotoLibraryError.notAuthorized).eraseToAnyPublisher()
                }
                return Future<Void, Error> { promise in
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCreationRequest.creationRequestForAsset(from: image)
                    }, completionHandler: { success, error in
                        if success {
                            promise(.success(()))
                        } else {
                            promise(.failure(error ?? PhotoLibraryError.saveFailed))
                        }
                    })
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}


