//
//  CustomeSchemeHandler.swift
//  flutter_inappwebview
//
//  Created by Lorenzo Pichilli on 25/10/2019.
//

import Flutter
import Foundation
import WebKit

actor SchemeActor {
//    schemeHandlers[hash] = urlSchemeTask
    var schemeHandlers: [Int:WKURLSchemeTask] = [:]
    func add(key: Int, value: WKURLSchemeTask) {
        schemeHandlers[key] = value
    }
    
    func remove(for key: Int) {
        schemeHandlers.removeValue(forKey: key)
    }
}
let schemeActor =  SchemeActor()

@available(iOS 11.0, *)
public class CustomSchemeHandler : NSObject, WKURLSchemeHandler {
//    var schemeHandlers: [Int:WKURLSchemeTask] = [:]
    public static var proxyHost: String?
    public static var proxyPort: Int?
    
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let hash = urlSchemeTask.hash
//        schemeHandlers[hash] = urlSchemeTask
        
        
        Task.detached(priority: .high, operation: {
            await schemeActor.add(key: hash, value: urlSchemeTask)
            do {
                let configuration = URLSessionConfiguration.default
                if let host = CustomSchemeHandler.proxyHost,
                   let port = CustomSchemeHandler.proxyPort {
                    configuration.connectionProxyDictionary = [
                        "HTTPEnable": true,
                        "HTTPProxy": host,
                        "HTTPPort": port,
                        "HTTPSEnable": true,
                        "HTTPSProxy": host,
                        "HTTPSPort": port,
                    ]
                }
                
                configuration.timeoutIntervalForRequest = 5
                configuration.timeoutIntervalForResource = 5
                let session = URLSession(configuration: configuration)
                
                let (data, response) = try await session.data(for: urlSchemeTask.request)
                
                if await (schemeActor.schemeHandlers[hash] != nil) {
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                    // print("task: url:\(urlSchemeTask.request.url?.absoluteString ?? "unknown url") did finished")
                    
                }
                
            } catch {
                print("task: url:\(urlSchemeTask.request.url?.absoluteString ?? "unknown url") error: \(error)")
            }
            await schemeActor.remove(for: hash)
            
        })
        // let inAppWebView = webView as! InAppWebView
        // let request = WebResourceRequest.init(fromURLRequest: urlSchemeTask.request)
        // let callback = WebViewChannelDelegate.LoadResourceWithCustomSchemeCallback()
        // callback.nonNullSuccess = { (response: CustomSchemeResponse) in
        //     if (self.schemeHandlers[urlSchemeTask.hash] != nil) {
        //         let urlResponse = URLResponse(url: request.url, mimeType: response.contentType, expectedContentLength: -1, textEncodingName: response.contentEncoding)
        //         urlSchemeTask.didReceive(urlResponse)
        //         urlSchemeTask.didReceive(response.data)
        //         urlSchemeTask.didFinish()
        //         self.schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
        //     }
        //     return false
        // }
        // callback.error = { (code: String, message: String?, details: Any?) in
        //     print(code + ", " + (message ?? ""))
        // }
        
        // if let channelDelegate = inAppWebView.channelDelegate {
        //     channelDelegate.onLoadResourceWithCustomScheme(request: request, callback: callback)
        // } else {
        //     callback.defaultBehaviour(nil)
        // }
    }
    
    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        Task.detached {
            await schemeActor.remove(for: urlSchemeTask.hash)
        }
//        schemeHandlers.removeValue(forKey: urlSchemeTask.hash)
    }
}
