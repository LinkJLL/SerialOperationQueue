//
//  SerialOperationQueue.swift
//  SerialOperationQueue
//
//  Created by JL on 2025/6/22.
//

import UIKit

class SerialOperationQueue<T>: OperationQueue, @unchecked Sendable {
    private let queue: OperationQueue
    private let lock = NSLock()
    private var _currentTask: UploadTask<T>?
    private var monitorInterval: TimeInterval = 60
    private var monitoringTimer: DispatchSourceTimer?
    private var lastKey: String?
    var currentTask: UploadTask<T>? {
        lock.lock(); defer { lock.unlock() }
        return _currentTask
    }
    init(maxConcurrentOperationCount : Int = 1) {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = maxConcurrentOperationCount
    }
    func addTask(key: String,
                 file : T,
                 _ work: @escaping (UploadTask<T>) -> Void) {
        let task = UploadTask(key: key, file: file, work: work)
        task.completionBlock = { [weak self, weak task] in
            guard let self, let task else { return }
            self.lock.lock()
            if self._currentTask === task {
                self._currentTask = nil
            }
            self.lock.unlock()
            self.checkAndStopMonitoring()
        }
        
        task.onDidStart = { [weak self] op in
            guard let self = self else { return }
            self.lock.lock()
            self._currentTask = op
            self.lock.unlock()
            // 取消旧定时器()
            self.stopMonitoring()
            self.startMonitoringIfNeeded()
        }
        queue.addOperation(task)
    }
    
    func cancelAllTasks() {
        self.stopMonitoring()
        self.queue.cancelAllOperations()
        self.checkAndStopMonitoring()
    }
    
    private func startMonitoringIfNeeded() {
        guard monitoringTimer == nil else { return }
        guard let task = _currentTask else { return }
        let key = task.key
        self.lastKey = key
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + monitorInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            if let current = self._currentTask, current.key == key, current.isExecuting {
                // 自动取消任务 并上报
                current.cancel()
                self.stopMonitoring()
            }
        }
        
        monitoringTimer = timer
        timer.resume()
    }
    
    private func checkAndStopMonitoring() {
        if queue.operations.isEmpty {
            stopMonitoring()
        }
    }
    
    private func stopMonitoring() {
        monitoringTimer?.cancel()
        monitoringTimer = nil
    }
}
