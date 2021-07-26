//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

private struct Image: Decodable {
	let image_id: UUID
	let image_desc: String?
	let image_loc: String?
	let image_url: URL
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
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }

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
			let items: [Image]
		}

		static func map(_ data: Data, from response: HTTPURLResponse) throws -> [Image] {
			guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data)
			else {
				throw RemoteFeedLoader.Error.invalidData
			}
			return root.items
		}
	}
}

private extension Array where Element == Image {
	func toModels() -> [FeedImage] {
		return map { FeedImage(id: $0.image_id, description: $0.image_desc, location: $0.image_loc, url: $0.image_url) }
	}
}
