// JobsJSONExporter.swift
import Foundation

// MARK: - JSON Exporter

/// A lightweight utility that serialises the hard‑coded job catalog to a JSON file.
struct JobsJSONExporter {

    /// Writes the sample jobs to a file named `sample_jobs.json` in the app’s Documents directory.
    ///
    /// If the file already exists, it will be overwritten.
    /// Errors are thrown so the caller can decide how to handle them.
    ///
    /// - Throws: Any error that occurs during encoding or file writing.
    static func writeSampleJobsToFile() throws {
        // 1️⃣ Grab the sample jobs
        let jobs = HardcodedJobs.sampleJobs()

        // 2️⃣ Encode them to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]   // optional, make output readable
        let data = try encoder.encode(jobs)

        // 3️⃣ Get a target URL (📁 Documents directory)
        let fileURL = try fileURLForSampleJobs()

        // 4️⃣ Write the data
        try data.write(to: fileURL, options: [.atomic])
        print("✅ Sample jobs written to \(fileURL.path)")
    }

    // MARK: - Private helpers

    /// Returns a URL inside the app’s Documents directory suitable for storing the JSON file.
    ///
    /// - Throws: If the Documents directory can’t be found.
    private static func fileURLForSampleJobs() throws -> URL {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "JobsJSONExporter", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not locate documents directory."
            ])
        }
        return documentsURL.appendingPathComponent("sample_jobs.json")
    }
}
