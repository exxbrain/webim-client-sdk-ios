//
//  MemoryHistoryStorage.swift
//  WebimClientLibrary
//
//  Created by Nikita Lazarev-Zubov on 11.08.17.
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

final class MemoryHistoryStorage: HistoryStorage {
    
    // MARK: - Properties
    private let majorVersion = Int(InternalUtils.getCurrentTimeInMicrosecond() % Int64.max)
    private lazy var historyMessages = [MessageImpl]()
    private var reachedHistoryEnd: Bool?
    
    
    // MARK: - Initialization
    
    init() {
        // Empty initializer introduced because of init(with:) existence.
    }
    
    // For testing purposes only.
    init(with messagesToAdd: [MessageImpl]) {
        for message in messagesToAdd {
            historyMessages.append(message)
        }
    }
    
    
    // MARK: - Methods
    // MARK: HistoryStorage protocol methods
    
    func getMajorVersion() -> Int {
        return majorVersion
    }
    
    func set(reachedHistoryEnd: Bool) {
        // No need in this implementation.
    }
    
    func getLatestBy(limitOfMessages: Int,
                     completion: @escaping ([Message]) throws -> ()) throws {
        try respondTo(messages: historyMessages,
                      limitOfMessages: limitOfMessages,
                      completion: completion)
    }
    
    func getBefore(id: HistoryID,
                   limitOfMessages: Int,
                   completion: @escaping ([Message]) throws -> ()) throws {
        let sortedMessages = historyMessages.sorted { $0.getHistoryID()!.getTimeInMicrosecond() < $1.getHistoryID()!.getTimeInMicrosecond() }
        
        if sortedMessages[0].getHistoryID()!.getTimeInMicrosecond() > id.getTimeInMicrosecond() {
            try completion([MessageImpl]())
            return
        }
        
        for message in sortedMessages {
            if message.getHistoryID() == id {
                try respondTo(messages: sortedMessages,
                              limitOfMessages: limitOfMessages,
                              offset: sortedMessages.index(of: message)!,
                              completion: completion)
                break
            }
        }
    }
    
    func receiveHistoryBefore(messages: [MessageImpl],
                              hasMoreMessages: Bool) {
        if !hasMoreMessages {
            reachedHistoryEnd = true
        }
        
        historyMessages = messages + historyMessages
    }
    
    func receiveHistoryUpdate(messages: [MessageImpl],
                              idsToDelete: Set<String>,
                              completion: @escaping (_ endOfBatch: Bool, _ messageDeleted: Bool, _ deletedMesageID: String?, _ messageChanged: Bool, _ changedMessage: MessageImpl?, _ messageAdded: Bool, _ addedMessage: MessageImpl?, _ idBeforeAddedMessage: HistoryID?) throws -> ()) throws {
        try deleteFromHistory(idsToDelete: idsToDelete,
                              completion: completion)
        try mergeHistoryChanges(messages: messages,
                                completion: completion)
        try completion(true, false, nil, false, nil, false, nil, nil)
    }
    
    
    // MARK: Private methods
    private func respondTo(messages: [MessageImpl],
                           limitOfMessages: Int,
                           completion: ([Message]) throws -> ()) throws {
        try completion((messages.count == 0) ? messages : ((messages.count <= limitOfMessages) ? messages : Array(messages[(messages.count - limitOfMessages) ..< messages.count])))
    }
    
    private func respondTo(messages: [MessageImpl],
                           limitOfMessages: Int,
                           offset: Int,
                           completion: ([Message]) throws -> ()) throws {
        let supposedQuantity = offset - limitOfMessages
        try completion(Array(messages[((supposedQuantity > 0) ? supposedQuantity : 0) ..< offset]))
    }
    
    private func deleteFromHistory(idsToDelete: Set<String>,
                                   completion: (_ endOfBatch: Bool, _ messageDeleted: Bool, _ deletedMesageID: String?, _ messageChanged: Bool, _ changedMessage: MessageImpl?, _ messageAdded: Bool, _ addedMessage: MessageImpl?, _ idBeforeAddedMessage: HistoryID?) throws -> ()) throws {
        for message in historyMessages {
            if idsToDelete.contains((message.getHistoryID()?.getDBid())!) {
                historyMessages.remove(at: historyMessages.index(of: message)!)
                try completion(false, true, message.getHistoryID()?.getDBid(), false, nil, false, nil, nil)
            }
        }
    }
    
    private func mergeHistoryChanges(messages: [MessageImpl],
                                     completion: (_ endOfBatch: Bool, _ messageDeleted: Bool, _ deletedMesageID: String?, _ messageChanged: Bool, _ changedMessage: MessageImpl?, _ messageAdded: Bool, _ addedMessage: MessageImpl?, _ idBeforeAddedMessage: HistoryID?) throws -> ()) throws  {
        // FIXME: Refactor this if you dare!
        /*
         Algorithm merges messages with history messages.
         Messages before first history message are ignored.
         Messages with the same time in Microseconds with corresponding history messages are replacing them.
         Messages after last history message are added in the end.
         The rest of the messages are merged in the middle of history messages.
         */
        
        var receivedMessages = messages
        var result = [MessageImpl]()
        
        outerLoop: for historyMessage in historyMessages {
            while receivedMessages.count > 0 {
                for message in receivedMessages {
                    if message.getTimeInMicrosecond() < historyMessage.getTimeInMicrosecond() {
                        if result.count == 0 {
                            receivedMessages.remove(at: 0)
                            
                            break
                        } else {
                            result.append(message)
                            try completion(false, false, nil, false, nil, true, message, historyMessage.getHistoryID())
                            
                            receivedMessages.remove(at: 0)
                            
                            continue
                        }
                    }
                    
                    if message.getTimeInMicrosecond() > historyMessage.getTimeInMicrosecond() {
                        result.append(historyMessage)
                        
                        continue outerLoop
                    }
                    
                    if message.getTimeInMicrosecond() == historyMessage.getTimeInMicrosecond() {
                        result.append(message)
                        try completion(false, false, nil, true, message, false, nil, nil)
                        
                        receivedMessages.remove(at: 0)
                        
                        continue outerLoop
                    }
                }
            }
            
            result.append(historyMessage)
        }
        
        if receivedMessages.count > 0 {
            for message in receivedMessages {
                result.append(message)
                try completion(false, false, nil, false, nil, true, message, nil)
            }
        }
        
        historyMessages = result
    }
        
}
