//
//  UploadOperation.swift
//  SerialOperationQueue
//
//  Created by JL on 2025/6/22.
//

import UIKit
protocol UploadTaskDelegate: NSObjectProtocol {
    func startOperation<T>(with file : T?, operation: UploadTask<T>)
}
class UploadTask<T>: Operation, @unchecked Sendable {
    let key: String
    private let work: (UploadTask<T>) -> Void
    //开始回调
    var onDidStart: ((UploadTask) -> Void)?
    private var _executing = false
    private var _finished = false
    weak var operationDelegate : UploadTaskDelegate?
    override var isAsynchronous: Bool { true }
    override var isExecuting: Bool { _executing }
    override var isFinished: Bool { _finished }
    private var file: T?
    init(key: String,
         file : T,
         work: @escaping (UploadTask<T>) -> Void) {
        self.key = key
        self.work = work
        self.file = file
    }
    override func start() {
        if isCancelled {
            finish()
            return
        }
        self.onDidStart?(self)
        work(self)
        self._executing = true
        self.uploader()
    }

    func uploader() {
        self.operationDelegate?.startOperation(with: self.file, operation: self)
    }
    func finish() {
        debugPrint("任务结束 \(self.key)")
        willChangeValue(for: \.isExecuting)
        willChangeValue(for: \.isFinished)
        _executing = false
        _finished = true
        didChangeValue(for: \.isExecuting)
        didChangeValue(for: \.isFinished)
    }
    
}
