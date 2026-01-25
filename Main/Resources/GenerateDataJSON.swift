// GenerateDataJSON.swift
//
// Run this once (Command‑R) and it will create a `data.json` file
// in the project’s source‑tree root. The JSON matches the array
// returned by HardcodedJobs.sampleJobs().
//

import Foundation

// The entry‑point for a Swift script/command‑line style file.
//@main
struct DataJSONGenerator {
    static func main() {
        // 0️⃣ Resolve the directory that contains the project root.
        //    `FileManager.default.currentDirectoryPath` points to the
        //    directory Xcode launches the process from, which is the
        //    project root when you run the file directly.
        let projectRoot = FileManager.default.currentDirectoryPath

        // 1️⃣ Get the jobs from the existing HardcodedJobs helper.
        //    This assumes `HardcodedJobs.sampleJobs()` returns an
        //    encodable collection (e.g. `[Job]`).
        let jobs = HardcodedJobs.sampleJobs()

        // 2️⃣ Encode them as pretty‑printed JSON.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData: Data
        do {
            jsonData = try encoder.encode(jobs)
        } catch {
            fatalError("Failed to encode jobs: \(error)")
        }

        // 3️⃣ Write the JSON to `data.json` in the project root.
        let jsonURL = URL(fileURLWithPath: "\(projectRoot)/data.json")
        do {
            try jsonData.write(to: jsonURL, options: .atomic)
            print("✅ `data.json` written to \(jsonURL.path)")
        } catch {
            fatalError("Failed to write JSON file: \(error)")
        }
    }
}
