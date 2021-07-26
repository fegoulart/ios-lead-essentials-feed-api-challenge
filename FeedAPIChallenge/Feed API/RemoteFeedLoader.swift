//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

struct Image: Decodable {
	let id: UUID
	let description: String?
	let location: String?
	let url: URL
}

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public typealias Result = FeedLoader.Result

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { result in
			switch result {
			case let .success((data, response)): completion(RemoteFeedLoader.map(data, from: response))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}

	private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
		do {
			let items = try FeedImagesMapper.map(data, from: response)
			return .success(items.toModels())
		} catch {
			return .failure(error)
		}
	}

	private class FeedImagesMapper {
		private static var OK_200: Int { return 200 }

		private struct Root: Decodable {
			let images: [Image]
		}

		static func map(_ data: Data, from response: HTTPURLResponse) throws -> [Image] {
			guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data)
			else {
				throw RemoteFeedLoader.Error.invalidData
			}
			return root.images
		}
	}
}

private extension Array where Element == Image {
	func toModels() -> [FeedImage] {
		return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
	}
}
