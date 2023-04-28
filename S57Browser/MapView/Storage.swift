//
//  Storage.swift
//  ChartCalculator
//
//  Created by FrSaoud M. Rizwan
//  Adapted by F Gorina on 18/1/23.
//  Including iCloud
//
import Foundation

public class Storage {
    
    fileprivate init() { }
    
    enum Directory {
        // Only documents and other data that is user-generated, or that cannot otherwise be recreated by your application, should be stored in the <Application_Home>/Documents directory and will be automatically backed up by iCloud.
        case documents
        
        // Data that can be downloaded again or regenerated should be stored in the <Application_Home>/Library/Caches directory. Examples of files you should put in the Caches directory include database cache files and downloadable content, such as that used by magazine, newspaper, and map applications.
        case caches
        
        // Data that would be in iCloud container in Documents folder. If it is not accessible local Documents will be used
        
        
        case icloud
    }
    
    /// Returns URL constructed from specified directory
    static  func getURL(for directory: Directory) -> URL {
        var searchPathDirectory: FileManager.SearchPathDirectory
        
        switch directory {
        case .documents:
            searchPathDirectory = .documentDirectory
            if let url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
                return url
            } else {
                fatalError("Could not create URL for documents directory!")
            }
        case .caches:
            searchPathDirectory = .cachesDirectory
            if let url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
                return url
            } else {
                fatalError("Could not create URL for cache directory!")
            }
            
            
        case .icloud:
            if let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
                let tryURL = containerURL.appending(component: "Documents")
                do {
                    let exists = Storage.fileExistsInIcloud(tryURL)
                    if !exists {
                        try FileManager.default.createDirectory(at: tryURL, withIntermediateDirectories: true)
                    }
                    
                    return tryURL
                }catch{
                    fatalError("Could not create URL for iclñoud directory: \(error.localizedDescription)")
                }

            }else {
                 
                return getURL(for: .documents)
            }
        }
    }
    
    
    /// Store an encodable struct to the specified directory on disk
    ///
    /// - Parameters:
    ///   - object: the encodable struct to store
    ///   - directory: where to store the struct
    ///   - fileName: what to name the file where the struct data will be stored
    static func store<T: Encodable>(_ object: T, to directory: Directory, as fileName: String) where T : Encodable{
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    
    static func storeCoordinated<T: Encodable>(_ object: T, to directory: Directory, as fileName: String) where T : Encodable{
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        
        coordinator.coordinate(writingItemAt: url, error: &error) { URLaurl in
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(object)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
            } catch {
                fatalError(error.localizedDescription)
            }

        }
    }

    
    /// Retrieve and convert a struct from a file on disk
    ///
    /// - Parameters:
    ///   - fileName: name of the file where struct data is stored
    ///   - directory: directory where struct data is stored
    ///   - type: struct type (i.e. Message.self)
    /// - Returns: decoded struct model(s) of data
    static func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type)  throws  -> T  where T : Encodable{
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        
        if !Storage.fileExists(fileName, in: directory) {
            throw NSError(domain: "Storaga", code: 0)
            
            
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {

            let decoder = JSONDecoder()
            
            let model = try decoder.decode(type, from: data)
            return model
      
        } else {
            throw NSError(domain: "Storaga", code: 1)
        }
    }
    
    static func retrieveCoordinated<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type, action: (T)  -> Void)  where T : Encodable{
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        coordinator.coordinate(readingItemAt: url, error: &error) { aurl in
            if let data = FileManager.default.contents(atPath: aurl.path) {

                let decoder = JSONDecoder()
                do {
                    let model = try decoder.decode(type, from: data)
                    action( model)
                } catch {
                    //fatalError(error.localizedDescription)
                }
            } else {
                print("No data found at \(url) - \(aurl)")
            }
            
            
        }
        if let err = error {
            print(err)
            fatalError(err.localizedDescription)
        }
    }
    
    
    
    
    /// Remove all files at specified directory
    static func clear(_ directory: Directory) {
        let url = getURL(for: directory)
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Remove specified file from specified directory
    static func remove(_ fileName: String, from directory: Directory) {
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    static func fileExistsInIcloud(_ url : URL) -> Bool{
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        coordinator.coordinate(readingItemAt: url, error: &error) { url in
            
        }
        if let err = error {
            print(err)
            return false
            
        }else {
            return true
        }
    }
    
    /// Returns BOOL indicating whether file exists at specified directory with specified file name
    static func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        if directory == .icloud {
            return fileExistsInIcloud(getURL(for: directory).appendingPathComponent(fileName, isDirectory: false))
        }
        let url = getURL(for: directory).appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path)
    }
}
