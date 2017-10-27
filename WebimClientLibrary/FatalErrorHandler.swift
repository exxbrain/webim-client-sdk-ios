//
//  FatalErrorHandler.swift
//  WebimClientLibrary
//
//  Created by Nikita Lazarev-Zubov on 08.08.17.
//  Copyright © 2017 Webim. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/**
 - SeeAlso:
 `SessionBuilder.set(fatalErrorHandler:)`
 */
public protocol FatalErrorHandler {
    
    /**
     This method is to be called when a fatal error occurs.
     - important:
     Notice that the session will be destroyed before this method is called.
     - parameter error:
     Error type.
     */
    func on(error: WebimError)
    
}

// MARK: -
public enum FatalErrorType {
    
    /**
     Indicates that the account in Webim service has been disabled (e.g. for non-payment). The error is unrelated to the user’s actions.
     Recommended response is to show the user an error message with a recommendation to try using the chat later.
     */
    case ACCOUNT_BLOCKED
    
    /**
     Indicates an expired authorization of a visitor.
     The recommended response is to reauthorize it and to recreate a session.
     - SeeAlso:
     `Webim.SessionBuilder.set(visitorFieldsJSON jsonString:)`
     `Webim.SessionBuilder.set(visitorFieldsJSON jsonData:)`
     */
    case PROVIDED_VISITOR_EXPIRED
    
    /**
     Indicates the occurrence of an unknown error.
     Recommended response is to send an automatic bug report and show to a user an error message with the recommendation to try using the chat later.
     - SeeAlso:
     `WebimError.getErrorString()`
     */
    case UNKNOWN
    
    /**
     Indicates that a visitor was banned by an operator and can't send messages to a chat anymore.
     Occurs when a user tries to open the chat or write a message after that.
     Recommended response is to show the user an error message with the recommendation to try using the chat later or explain to the user that it was blocked for some reason.
     */
    case VISITOR_BANNED
    
    /**
     Indicates a problem of your application authorization mechanism and is unrelated to the user’s actions.
     Occurs when trying to authorize a visitor with a non-valid signature.
     Recommended response is to send an automatic bug report and show the user an error message with the recommendation to try using the chat later.
     - SeeAlso:
     `Webim.SessionBuilder.set(visitorFieldsJSON jsonString:)`
     `Webim.SessionBuilder.set(visitorFieldsJSON jsonData:)`
     */
    case WRONG_PROVIDED_VISITOR_HASH
    
}
