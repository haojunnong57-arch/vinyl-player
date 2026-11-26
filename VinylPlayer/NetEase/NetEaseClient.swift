import Foundation

/// 网易云音乐直连客户端。
/// 不需要自建 API 服务：搜索/专辑/播放试听走 music.163.com 官方接口，
/// 付费/会员曲目需要用户在设置里粘贴 MUSIC_U cookie。
enum NetEase {
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    static var cookie: String {
        get { UserDefaults.standard.string(forKey: "netease.cookie") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "netease.cookie") }
    }
}

enum NetEaseError: LocalizedError {
    case badResponse(String)
    case empty(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let m): return "网易云返回异常：\(m)"
        case .empty(let m): return m
        }
    }
}

enum NetEaseClient {
    private static func request(path: String, method: String = "GET", form: [String: String]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: "https://music.163.com" + path) else {
            throw NetEaseError.badResponse("URL 拼装失败")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 25
        request.setValue(NetEase.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://music.163.com/", forHTTPHeaderField: "Referer")
        request.setValue("https://music.163.com", forHTTPHeaderField: "Origin")
        if !NetEase.cookie.isEmpty {
            request.setValue(NetEase.cookie, forHTTPHeaderField: "Cookie")
        }
        if let form {
            var comps = URLComponents()
            comps.queryItems = form.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.httpBody = (comps.percentEncodedQuery ?? "").data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw NetEaseError.badResponse("HTTP \(http.statusCode)")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetEaseError.badResponse("非 JSON 响应")
        }
        return json
    }

    // MARK: 搜索专辑

    static func searchAlbums(keyword: String, limit: Int = 30) async throws -> [Album] {
        let json = try await request(
            path: "/api/search/get/web",
            method: "POST",
            form: ["s": keyword, "type": "10", "limit": "\(limit)", "offset": "0"]
        )
        guard let result = json["result"] as? [String: Any],
              let albums = result["albums"] as? [[String: Any]] else {
            throw NetEaseError.empty("没搜到专辑")
        }
        return albums.compactMap { item in
            guard let id = item["id"] as? Int64 ?? (item["id"] as? Int).map(Int64.init) else { return nil }
            let name = item["name"] as? String ?? "未知专辑"
            let artist = (item["artist"] as? [String: Any])?["name"] as? String ?? ""
            let pic = item["picUrl"] as? String ?? ""
            return Album(
                id: id,
                name: name,
                artist: artist,
                coverURL: scaledURL(pic),
                tracks: [],
                cover: nil,
                tint: nil
            )
        }
    }

    // MARK: 专辑详情

    static func albumDetail(id: Int64) async throws -> Album {
        let json = try await request(path: "/api/album/\(id)")
        guard let album = json["album"] as? [String: Any] else {
            throw NetEaseError.empty("专辑不存在或需要登录")
        }
        let name = album["name"] as? String ?? "未知专辑"
        let artist = (album["artist"] as? [String: Any])?["name"] as? String ?? ""
        let pic = album["picUrl"] as? String ?? ""
        let songs = album["songs"] as? [[String: Any]] ?? []

        let tracks: [Track] = songs.compactMap { song in
            guard let sid = song["id"] as? Int64 ?? (song["id"] as? Int).map(Int64.init) else { return nil }
            let title = song["name"] as? String ?? "未知曲目"
            let ms = song["dt"] as? Double ?? (song["dt"] as? Int).map(Double.init) ?? 0
            let artists = (song["ar"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
            let songPic = ((song["al"] as? [String: Any])?["picUrl"] as? String) ?? pic
            return Track(
                id: sid,
                name: title,
                artist: artists.joined(separator: "/"),
                albumName: name,
                duration: ms / 1000.0,
                coverURL: scaledURL(songPic)
            )
        }

        return Album(
            id: id,
            name: name,
            artist: artist,
            coverURL: scaledURL(pic),
            tracks: tracks,
            cover: nil,
            tint: nil
        )
    }

    // MARK: 播放地址

    /// 先走官方试听重定向，能播就播；失败提示用户填 cookie。
    static func playableURL(for track: Track) -> URL? {
        track.streamURL
    }

    static func scaledURL(_ raw: String, size: Int = 1000) -> URL? {
        guard !raw.isEmpty else { return nil }
        var url = raw
        if url.hasPrefix("http://") {
            url = "https://" + url.dropFirst(7)
        }
        if url.contains("?") {
            url += "&param=\(size)y\(size)"
        } else {
            url += "?param=\(size)y\(size)"
        }
        return URL(string: url)
    }

    /// 原始探测：HTTP 状态 + 响应前 300 字，用来判断卡在哪一步
    static func probe(keyword: String) async -> String {
        guard let url = URL(string: "https://music.163.com/api/search/get/web") else {
            return "URL 拼装失败"
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue(NetEase.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://music.163.com/", forHTTPHeaderField: "Referer")
        if !NetEase.cookie.isEmpty {
            request.setValue(NetEase.cookie, forHTTPHeaderField: "Cookie")
        }
        let encoded = "s=\(keyword.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? keyword)&type=10&limit=3&offset=0"
        request.httpBody = encoded.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let head = String(data: data.prefix(300), encoding: .utf8) ?? "<非文本响应>"
            return "HTTP \(code)\n\(head)"
        } catch {
            return "请求失败：\(error.localizedDescription)"
        }
    }
}
