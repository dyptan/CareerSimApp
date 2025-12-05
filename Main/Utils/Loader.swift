import Foundation

// Switch to V6 data (denormalized with embedded details)
//var jobs: [Job] = loadJobsV6("dataV6.json")
// If you ever need to go back:
// var jobs: [Job] = loadJobsV5("dataV5.json")

private func loadJobsV6(_ filename: String) -> [Job] {
    guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    do {
        return try JobV6Adapter.loadJobs(from: url)
    } catch {
        fatalError("Couldn't parse \(filename) as V6 jobs:\n\(error)")
    }
}


// Generic loader remains
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else { fatalError("Couldn't find \(filename) in main bundle.") }
    do { data = try Data(contentsOf: file) } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
