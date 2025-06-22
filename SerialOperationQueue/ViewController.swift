//
//  ViewController.swift
//  SerialOperationQueue
//
//  Created by JL on 2025/6/22.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var taskCount: UILabel!
    var taskTatal : Int = 0
    lazy var queue: SerialOperationQueue = {
        let queue = SerialOperationQueue<Any>.init(maxConcurrentOperationCount: 1)
        return queue
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    @IBAction func addTask(_ sender: Any) {
        let key = self.generateStrongUniqueKey()
        queue.addTask(key: key, file: "") { operation in
            operation.operationDelegate = self
        }
        self.taskTatal += 1
        self.updateTaskCount()
    }
    
    func updateTaskCount() {
        DispatchQueue.main.async {
            self.taskCount.text = "Task Count: \(self.taskTatal)"
        }
    }
    
}
extension ViewController : UploadTaskDelegate{
    func startOperation<T>(with file: T?, operation: UploadTask<T>) {
        debugPrint("任务开始 \(operation.key)")
        //模拟异步请求数据
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 3, execute: {
            operation.finish()
            self.taskTatal -= 1
            self.updateTaskCount()
        })
    }
    func generateStrongUniqueKey(prefix: String = "task") -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let uuid = UUID().uuidString.prefix(6)
        return "\(prefix)_\(timestamp)_\(uuid)"
    }
}
