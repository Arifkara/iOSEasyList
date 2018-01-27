//
//  Diffable.swift
//  ListUpdater
//
//  Created by Joe's MacBook Pro on 2017/7/9.
//  Copyright © 2017年 joe. All rights reserved.
//

import Foundation

/****
 https://github.com/NSJoe/ListUpdater/
 ****/

//MARK:- Diffable
public protocol Diffable {
    var diffIdentifier : String {get}
    func isEqual(to object: Any) -> Bool
}

public extension Diffable {
    func isEqual(to object: Any) -> Bool{
        guard  type(of: self) == type(of: object),
            let to = object as? Diffable
            else { return false }
        
        return diffIdentifier == to.diffIdentifier
    }
}


public struct IndexMovement : Hashable {
    public var from = 0
    public var to = 0
    
    public var hashValue: Int {
        get {
            return "\(from)-\(to)".hashValue
        }
    }
    
    public static func ==(lhs: IndexMovement, rhs: IndexMovement) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public struct DiffIndexResult {
    public var deletes = IndexSet()
    public var inserts = IndexSet()
    public var reloads = IndexSet()
    public var moveIndexes = Set<IndexMovement>()
    
    public var changedCount : Int {
        get{
            return deletes.count + inserts.count + moveIndexes.count
        }
    }
    
    public mutating func deletes(at index:Int) -> Void {
        deletes.insert(index)
    }
    
    public mutating func insert(at index:Int) -> Void {
        inserts.insert(index)
    }
    
    public mutating func reloads(at index:Int) -> Void {
        reloads.insert(index)
    }
    
    public mutating func moveIndex(at move:IndexMovement) -> Void {
        moveIndexes.insert(move)
    }
}

public func indexedDiff(from:Array<Diffable>, to:Array<Diffable>) -> DiffIndexResult {
    var diffResult = DiffIndexResult()
    var oldIds = [String](), newIds = [String](), oldIndexMap = [String:Int](), newIndexMap = [String:Int](), expectIndexes = Array<String>()
    
    for item in from {
        oldIds.append(item.diffIdentifier)
    }
    for item in to {
        newIds.append(item.diffIdentifier)
    }
    
    for (index, item) in from.enumerated() {
        expectIndexes.append(item.diffIdentifier)
        if newIds.contains(item.diffIdentifier) {
            oldIndexMap[item.diffIdentifier] = index
        } else {
            diffResult.deletes(at: index)
        }
    }
    
    expectIndexes = expectIndexes.filter { return !diffResult.deletes.contains(expectIndexes.index(of: $0)!) }
    
    for (index, item) in to.enumerated() {
        if oldIds.contains(item.diffIdentifier) {
            newIndexMap[item.diffIdentifier] = index
        } else {
            diffResult.insert(at: index)
            expectIndexes.insert(item.diffIdentifier, at: index)
        }
    }
    
    for (key, _) in oldIndexMap {
        assert(newIndexMap.keys.contains(key), "对应key不存在")
        let fromIndex = oldIndexMap[key]!
        let expectIndex = expectIndexes.index(of: key)
        let toIndex = newIndexMap[key]!
        if expectIndex == nil {
            continue
        }
        let isChanged = !from[fromIndex].isEqual(to: to[toIndex])
        if expectIndex == toIndex {
            if isChanged {
                diffResult.reloads(at: fromIndex)
            }
            continue
        }
        
        diffResult.moveIndex(at: IndexMovement(from: fromIndex, to: toIndex))
    }
    
    return diffResult
}




//MARK:- SectionDiffable
public protocol SectionDiffable : Diffable {
    var sectionItems : Array<Diffable> { get }
    
}

public struct RowsMovement : Hashable {
    public var from = IndexPath()
    public var to = IndexPath()
    
    public var hashValue: Int {
        get {
            return "\(from.section)-\(from.row)-\(from.item)-\(to.row)-\(to.item)".hashValue
        }
    }
    
    public static func ==(lhs: RowsMovement, rhs: RowsMovement) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public struct DiffSectionResult {
    public var deletes = [IndexPath]()
    public var inserts = [IndexPath]()
    public var reloads = [IndexPath]()
    public var moveRows = Set<RowsMovement>()
    
    public var changedCount : Int {
        get{
            return deletes.count + inserts.count + moveRows.count
        }
    }
    
    public mutating func deletes(at indexPath:IndexPath) -> Void {
        deletes.append(indexPath)
    }
    
    public mutating func insert(at indexPath:IndexPath) -> Void {
        inserts.append(indexPath)
    }
    
    public mutating func reloads(at indexPath:IndexPath) -> Void {
        reloads.append(indexPath)
    }
    
    public mutating func moveRow(at move:RowsMovement) -> Void {
        moveRows.insert(move)
    }
}

public func sectionedDiff(from:Array<SectionDiffable>, to:Array<SectionDiffable>) -> (DiffIndexResult, DiffSectionResult) {
    
    //计算一级数组的变化
    let indexedResult = indexedDiff(from: from, to: to)
    var sectionedResult = DiffSectionResult()
    
    for (section, item) in from.enumerated() {
        if indexedResult.deletes.contains(section) {
            continue
        }
        let fromArray = item.sectionItems
        var toArray:[Diffable]?
        var toSection = NSNotFound
        for (index, sectionInfo) in to.enumerated() {
            if sectionInfo.diffIdentifier == item.diffIdentifier {
                toArray = sectionInfo.sectionItems
                toSection = index
                break
            }
        }
        assert(toArray != nil && toSection != NSNotFound, "toArray在这里不可能为空, 第一个if判断已经排除了")
        let diffRowResult = indexedDiff(from: fromArray, to: toArray!)
        for (_, row) in diffRowResult.deletes.enumerated() {
            sectionedResult.deletes(at: IndexPath(row: row, section: section))
        }
        for (_, row) in diffRowResult.inserts.enumerated() {
            sectionedResult.insert(at: IndexPath(row: row, section: toSection))
        }
        
        for (_, row) in diffRowResult.reloads.enumerated() {
            sectionedResult.reloads(at: IndexPath(row: row, section: toSection))
        }
        
        for move in diffRowResult.moveIndexes {
            let indexPath = IndexPath(row: move.from, section: section)
            if sectionedResult.deletes.contains(indexPath) {
                continue
            }
            sectionedResult.moveRow(at: RowsMovement(from: indexPath, to: IndexPath(row: move.to, section: toSection)))
        }
    }
    return (indexedResult, sectionedResult)
}



struct SingleSection : SectionDiffable {
    
    var diffIdentifier: String = ""
    
    var sectionItems: Array<Diffable> = [Diffable]()
    
    init(items:[Diffable]) {
        sectionItems=items
    }
}



//MARK:- Foundation + Diffable
extension Int: Diffable {
    public var diffIdentifier: String {
        return String(self)
    }
}


extension String: Diffable {
    public var diffIdentifier: String {
        return self
    }
}


extension Float : Diffable {
    public var diffIdentifier: String {
        return String(self)
    }
}

extension Double : Diffable {
    public var diffIdentifier: String {
        return String(self)
    }
}

extension Date : Diffable {
    public var diffIdentifier: String {
        return self.description
    }
}
