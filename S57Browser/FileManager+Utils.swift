//
//  FIleManager+util.swift
//  GRAM_01
//
//  Created by Francisco Gorina Vanrell on 02/09/2019.
//  Copyright © 2019 Francisco Gorina. All rights reserved.
//

import Foundation

public enum FileExistence: Equatable {
    case none
    case file
    case directory
}

public func ==(lhs: FileExistence, rhs: FileExistence) -> Bool {
    
    switch (lhs, rhs) {
    case (.none, .none),
         (.file, .file),
         (.directory, .directory):
        return true
        
    default: return false
    }
}
extension FileManager {
    
    
    func getDocumentsDirectory() -> URL {
        let paths = self.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        if !URLExists(documentsDirectory){
            do {
                try createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
                Storage.store("Dummy.txt", to: .documents, as: "First Install")
            }catch{
                print("Cannot create Documents DIrectory")
            }
        }
        return documentsDirectory
    }
    
    func getAppSupportDirectory() -> URL {
        let paths = self.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDirectory = paths[0]
        return appSupportDirectory
    }
    
    
    func URLExists(_ url : URL) -> Bool {
        if !url.isFileURL{
            return false
        }
        let path = url.path
        return self.fileExists(atPath: path)
    }
    
    public func existence(atUrl url: URL) -> FileExistence {
        
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        switch (exists, isDirectory.boolValue) {
        case (false, _): return .none
        case (true, false): return .file
        case (true, true): return .directory
        }
    }
    
    func checkDirectoryAtURL(_ url : URL){
        do {
        switch(existence(atUrl: url)) {
        case .none :
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            
        case .file:
            try FileManager.default.removeItem(at: url)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        
        case .directory:
        break
           

        }
        } catch {
            print("Error \(error.localizedDescription) while chcking directory \(url.absoluteString)")
        }
}
func createTempDirectory() -> URL {
    
    let fileName = "filemanagertest-temp-dir.\(NSUUID().uuidString)"
    let fileUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    
    try! FileManager.default.createDirectory(at: fileUrl, withIntermediateDirectories: false, attributes: nil)
    
    return fileUrl
}

func generatedTempFileURL() -> URL {
    
    let fileName = "filemanagertest-temp.\(NSUUID().uuidString)"
    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    
    return fileURL
}

// Returns la UTI de un arxiu . Suposo
func getUTI(_ url : URL) -> String?{
    do {
        let typeIdentifier = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
        return typeIdentifier
    }catch{
        
    }
    
    return nil
}

    func filesAt(_ url : URL)  -> [URL]{
        
        do{
            return try self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        } catch {
            return []
        }
        
    }
}


