# Moya Structure
> SwiftUI 에서 REST API 를 사용하면서 Moya 라이브러리를 알게되었다. REST API 가 주로 사용되는 프로젝트를 하면서 다듬은 Moya 구조를 남긴다.

## 구조 

### MoyaProvider
- 아래에 나오는 함수는 모두 extension MoyaProvider 블럭에 구현되었다.
```
extension MoyaProvider {
    ...
}
```

### request 공통화
- Loading Progress Bar 처리 공통화
- Error 처리 공통화
- Api repeat Count 공통화

```swift
func request<T: Decodable>(_ target: Target, isLoading: Bool = true, isMultipart: Bool = false, repeatCount: Int = 3) async -> T? {
    CommonAPI.shared.setLoadingProgress(true, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
    do {
        let t: T = try await request(target, isLoading: isLoading, isMultipart: isMultipart)
        CommonAPI.shared.setLoadingProgress(false, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
        return t
    } catch {
        if await responseErrorHandle(error, repeatCount, ignore: !isLoading) {
            return await request(target, isMultipart: isMultipart, repeatCount: repeatCount - 1)
        } else {
            CommonAPI.shared.setLoadingProgress(false, log: target.typeString, isMultipart: isMultipart, ignore: !isLoading)
            return nil
        }
    }
}

private func request<T: Decodable>(_ target: Target, isLoading: Bool = true, isMultipart: Bool = false) async throws -> T {
    return try await withCheckedThrowingContinuation { continuation in
        self.request(target) { response in
            switch response {
            case .success(let result):
                do {
                    let networkResponse = try JSONDecoder().decode(HttpResponse<T>.self, from: result.data)
                    if let errorResponse = networkResponse.toHttpErrorResponse() {
                        continuation.resume(throwing: errorResponse)
                    } else {
                        continuation.resume(returning: networkResponse.body)
                    }
                } catch {
                    let errorResponse = (try? JSONDecoder().decode(HttpErrorResponse.self, from: result.data)) ?? .base
                    continuation.resume(throwing: errorResponse)
                }

            case .failure(let error):
                if let response = error.response?.data {
                    let errorResponse = try? JSONDecoder().decode(HttpErrorResponse.self, from: response)
                    continuation.resume(throwing: errorResponse ?? .base)
                } else {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
``` 

### Loading Progress Bar 처리 공통화
- setLoadingProgress(...) 함수 호출을 통해 Rxswift 로 처리되었다.
- log 에 target.typeString 을 넘겨 Loading UI 가 나타날 때 어떤 api 가 호출되었는지 log 를 남긴다.
- Loading UI 가 문제가 있는 경우 log 를 통해 어떤 api 에서 문제가 발생했는지 디버깅하기 편했다.

### Error 처리 공통화
- Server 에서 보내준 Error 처리 공통화했다. 이 경우 HttpErrorResponse 로 넘어오도록 정했다.
- REST API 에서 발생한 4xx, 5xx Erorr 처리 공통화했다. 이 경우 서버에서 정상적인 에러메세지를 앱에 보낸 경우가 아니다. 그래서 MoyaError 로 넘어왔다.

```swift
private func responseErrorHandle(_ error: Error, _ repeatCount: Int, ignore: Bool) async -> Bool {
    if ignore {
        return false
    }
    
    var isNext = true
    
    switch error {
        // Moya Failed API
    case let moyaError as MoyaError:
        if let response = moyaError.response?.data {
            let errorResponse = try? JSONDecoder().decode(HttpErrorResponse.self, from: response)
            await UIApplication.makeToastAsync(errorResponse?.message ?? HttpErrorResponse.base.message)
            isNext = false
        } else {
            if repeatCount <= 0 {
                await UIApplication.makeToastAsync(error.localizedDescription)
            }
        }
        
        // Server Failed API
    case let errorResponse as HttpErrorResponse:
        isNext = false
        
        let message = errorResponse.message
        let errorType = HttpResponseCodeType(rawValue: errorResponse.code)
        
        switch errorType {
        case .OK:
            break
            
            // MARK: - Common Error
        case .SYSTEM_ERROR:
            await UIApplication.makeToastAsync(message)
            
            // MARK: - add Error Type
            // ...
            
        case .none:
            await UIApplication.makeToastAsync(message)
        }
        
        assert(!isNext)
    default:
        if repeatCount <= 0 {
            await UIApplication.makeToastAsync(error.localizedDescription)
        }
    }
    
    if repeatCount <= 0 {
        isNext = false
    }
    
    return isNext
}
```

### Api repeat Count 공통화
- 처음에는 repeat Count 처리를 필요한 api 마다 했었다. 관리하기가 너무 불편하고 공통화하고 싶었다. 처음에는 구현하다 실패했는데 시간이 지나고 다시 구현하니 잘 작동했다.


<br>

## 실제 사용 코드 예제
- 이 예제 소스에는 실 사용 코드가 없다. 기회가 된다면 추후에 추가하겠다.

```swift
struct xxxModel: Decodable {
    ...
}

enum xxxTarget {
    case main
}

extension xxxTarget: CommonApiTarget {
    var path: String {
        switch self {
            /// xxxModel
        case .main:
            return "/main"
        }
        
    }
    
    var method: Moya.Method {
        switch self {
        case .main:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .main:
            return .requestPlain
        }
    }
}

extension DependencyValues {
    var xxxProvider: MoyaProvider<xxxTarget> {
        get { MoyaProvider<xxxTarget>.build() }
    }
}


@Dependency(\.xxxProvider) private var xxxProvider

@MainActor
func callMainApi(success: () -> Void) async {
    guard let resModel: xxxModel = await xxxProvider.request(.) else {
        // fail
        return
    }
    success()
}
```

