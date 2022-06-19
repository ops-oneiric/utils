//
//  Publisher.swift
//  Utilities
//
//  Created by William Preston Harrison on 6/19/22.
//
//  No copyright or restrictions pertain, except the absolute waiver of liability granted to the author in all cases whatsoever, including but not limited to any malfunction or damage resulting from the execution of this code, whether modified or not.

import Foundation

enum PublishingError: Error {
    case badURL
    case badLibraryItemURL(offender: String)
    case duplicateFilename(offender: String)
}

/// A generic class presenting an API for saving, loading, and deleting user-created `Model` objects.
/// Data is encoded in JSON format.
///
/// - Constraints: `Model: Encodable & Decodable & Hashable`
/// - Important: key path `directory` must be a writable, readable directory accessible via `FileManager.default`
///
/// Example use-case for a SwiftUI notes app, assuming some struct `Note` where `Note: Codable, Hashable`:
///
///     final class ViewModel: ObservableObject {
///         let publisher: Publisher<Note>
///         @Published private(set) var notes = [Note]()
///         init() {
///             let someUserDomainDirectoryURL = ...
///             publisher = .init(directory: someUserDomainDirectoryURL)
///             if let notes = try? publisher.loadPublishedData() {
///                 self.notes = notes
///             }
///         }
///         func refresh() {
///             if let notes = try? publisher.loadPublishedData() {
///                 self.notes = notes
///             }
///         }
///     }
///
///     struct NotesView: View {
///         @StateObject private var model = ViewModel()
///         var body: some View {
///             ...
///             List(model.notes, id: \.self) { savedNote in
///                 HStack {
///                     Text(savedNote.title)
///                     Spacer()
///                     Button {
///                         do {
///                             try model.publisher.delete(savedNote)
///                         } catch {...}
///                     } label: {
///                         Image(systemName: "trash")
///                     }
///                 }
///             }
///             ...
///         }
///     }
///
class Publisher<Model> where Model: Codable & Hashable {
    ///The URL of the (ideally user-domain) directory to which new model objects are published and from which existing are retrieved and deleted
    private(set) var directory: URL
    private var decoder = JSONDecoder(), encoder = JSONEncoder()
    //init
    ///Initializes the receiver.
    ///
    /// - Parameter directory: a URL pointing to the user-domain directory where model objects are stored
    init(directory: URL) {
        self.directory = directory
    }
    //MARK: - I/O
    ///Scans the contents of `directory` and returns an array of previously published model objects
    ///
    /// - Returns: an array of `Model` values, or [] if none found
    ///
    func loadPublishedData() throws -> [Model] {
        guard FileManager.default.fileExists(atPath: directory.absoluteString) else {
            throw PublishingError.badURL
        }
        var objects = [Model]()
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: directory.absoluteString) {
            for path in contents {
                let fileURL = URL(fileURLWithPath: path)
                guard FileManager.default.fileExists(atPath: path) else {
                    throw PublishingError.badLibraryItemURL(offender: path)
                }
                let data = try Data(contentsOf: fileURL)
                let modelObject = try decoder.decode(Model.self, from: data)
                objects.append(modelObject)
            }
        }
        return objects
    }
    ///Attempts to encode the contents of `object` into JSON and saves the data as a unique file within `directory`
    /// - Parameter object: the unique data to be saved
    func publish(_ object: Model) throws {
        let data = try encoder.encode(object)
        if !FileManager.default.fileExists(atPath: directory.absoluteString) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        let newURL = directory.appendingPathComponent(String(object.hashValue))
        guard !FileManager.default.fileExists(atPath: newURL.absoluteString) else {
            throw PublishingError.duplicateFilename(offender: newURL.absoluteString)
        }
        try data.write(to: newURL)
    }
    ///Attempts to locate within `directory` an object where `.hashValue` == `object.hashValue` and deletes it
    /// - Parameter object: the `Model` object whose data to delete
    func delete(_ object: Model) throws {
        let thisURL = directory.appendingPathComponent(String(object.hashValue))
        guard FileManager.default.fileExists(atPath: thisURL.absoluteString) else {
            throw PublishingError.badURL
        }
        try FileManager.default.removeItem(at: thisURL)
    }
    //  MARK: - URL generators
    ///Conveniently generate a URL for a directory that should not be exposed to or manipulated by the user
    /// - Parameter component: the string representing the final path component of the directory
    class func userLibraryDirectory(appending component: String) -> URL? {
        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }
        return libraryURL.appendingPathComponent(component)
    }
    ///Conveniently generate a URL for a directory that can exposed to (and therefore manipulated by) the Files app on iOS or iPadOS
    /// - Parameter component: the string representing the final path component of the directory
    class func userDocumentsDirectory(appending component: String) -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(component)
    }
}

