//
//  TableViewAdapter.swift
//  ListExample-iOS
//
//  Created by Mostafa Taghipour on 1/12/18.
//  Copyright © 2018 RainyDay. All rights reserved.
//

import UIKit

open class TableViewAdapter : ListAdapter , UITableViewDataSource,UITableViewDelegate {
    
    // constructors
    public init(tableView:UITableView,
                configCell : configCellType?=nil,
                didSelectItem : didSelectItemType?=nil) {
        super.init(listUpdater: TableViewUpdater(tableView: tableView))
        self.tableView=tableView
        self.tableView?.delegate=self
        self.tableView?.dataSource=self
        self.didSelectItem=didSelectItem
        
        if let configCell=configCell{
            self.configCell=configCell
        }
    }
    
    
    // variables
    public weak var tableView :UITableView?
  
    public  typealias configCellType = (_ tableView:UITableView,_ indexPath: IndexPath,_ data:Any?)->(UITableViewCell)
    public  var configCell:configCellType = {(_,_,_) in
        fatalError("Subclasses need to implement the configCell variable.")
    }
    
    public  typealias didSelectItemType = (_ data:Any?,_ indexPath:IndexPath)->()
    public var didSelectItem : didSelectItemType?
    
    internal override var emptyView:UIView?{
        didSet{
            guard let emptyView = emptyView else { return  }
            tableView?.backgroundView=emptyView
            
        }
    }
    
    
    //MARK:- UITableViewDataSource,UITableViewDelegate
    open func numberOfSections(in tableView: UITableView) -> Int {
        let count = sectionCount
        emptyView?.isHidden = count > 0
        return count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = getItemCount(in: section)
        if let collapsible = self as? Collapsible{
          return collapsible.isCollapsed(section: section) ? 0 : count
        }
        
        return count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return configCell(tableView,indexPath,getItem(indexPath: indexPath))
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectItem?(getItem(indexPath: indexPath), indexPath)
    }
}





