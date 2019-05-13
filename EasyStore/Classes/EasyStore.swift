//
//  EasyStore.swift
//  EasyStore
//
//  Created by Akira Matsuda on 2018/04/24.
//  Copyright © 2018 Akira Matsuda. All rights reserved.
//

import RealmSwift

open class EasyStore<T: Object> {
    public enum UpdateType : String {
        case add = "add"
        case update = "update"
        case delete = "delete"
    }
    
    public init() {
        
    }
    
    open func notificationName() -> String {
        return "EasyStoreUpdateNotification"
    }
    
    open func updateTypeKey() -> String {
        return "updateType"
    }
    
    open func transaction(_ handler: (_ realm: Realm) -> Void) throws {
        do {
            let realm = try Realm()
            try realm.write {
                handler(realm)
            }
        } catch {
            throw error
        }
    }
    
    open func postNotification(withUpdateType type: UpdateType) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: self.notificationName()), object: nil, userInfo: [self.updateTypeKey() : type]))
    }
    
    open func write(_ handler: @escaping (_ realm: Realm) -> Void) throws {
        do {
            try transaction { (realm) in
                handler(realm)
                postNotification(withUpdateType: .add)
            }
        } catch {
            throw error
        }
    }
    
    open func create(_ obj: T) throws {
        try self.add(obj, update: false)
    }
    
    open func add(_ obj: T, update: Bool = true) throws {
        do {
            try transaction { (realm) in
                realm.add(obj, update: update)
                postNotification(withUpdateType: .add)
            }
        } catch {
            throw error
        }
    }
    
    open func update(_ handler: @escaping () -> Void, silentUpdate: Bool = false) throws {
        do {
            try transaction { (realm) in
                handler()
                if silentUpdate == false {
                    postNotification(withUpdateType: .update)
                }
            }
        } catch {
            throw error
        }
    }
    
    open func delete(_ obj: T) throws {
        let realm = try Realm()
        try realm.write {
            realm.delete(obj)
            postNotification(withUpdateType: .delete)
        }
    }
    
    open func observe(_ handler: @escaping (UpdateType) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: self.notificationName()), object: nil, queue: nil) {
            if let userInfo = $0.userInfo {
                let type = userInfo[self.updateTypeKey()] as! UpdateType
                handler(type)
            }
        }
    }
    
    open func removeObserver(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }
}
