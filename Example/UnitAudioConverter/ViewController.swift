//
//  ViewController.swift
//  UnitAudioConverter
//
//  Created by Quang Tran on 06/29/2021.
//  Copyright (c) 2021 Quang Tran. All rights reserved.
//

import UIKit
import UnitAudioConverter

class ViewController: UIViewController {
    var tableView: UITableView { return view as! UITableView }
    
    override func loadView() {
        view = UITableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UAFileType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let item = UAFileType(rawValue: indexPath.row)
        cell.textLabel?.text = item?.name
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectingIndexPath = tableView.indexPathForSelectedRow,
           let item = UAFileType(rawValue: selectingIndexPath.row),
           let outputType = UAFileType(rawValue: indexPath.row),
           let filePath = Bundle.main.url(forResource: "file", withExtension: item.name) {
            
            let fileDestination = FileManager.default.temporaryDirectory.appendingPathComponent("file.\(outputType.name)")
            try? FileManager.default.removeItem(at: fileDestination)
            let fileInfo = UAConvertFileInfo(outputType: outputType, source: filePath, destination: fileDestination)
            
            UAConverter.shared.convert(fileInfo: fileInfo)
                .progress({ progress in
                    print("\(outputType.name): \(progress)")
                })
                .completion { [weak self] error in
                    print("finished: \(outputType.name)")
                    print(error as Any)
                    DispatchQueue.main.async {
                        self?.shareItem(fileDestination)
                    }
                }
            
            tableView.deselectRow(at: selectingIndexPath, animated: true)
            return nil
        }
        return indexPath
    }
    
    func shareItem(_ url: URL) {
        let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(share, animated: true, completion: nil)
    }
}


extension UAFileType {
    var name: String {
        return "\(self)"
    }
}
