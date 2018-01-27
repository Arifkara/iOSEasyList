//
//  MessageSendCell.swift
//  ListExample-iOS
//
//  Created by Mostafa Taghipour on 1/19/18.
//  Copyright © 2018 RainyDay. All rights reserved.
//

import UIKit
import iOSEasyList

class MessageSendCell: BaseTableViewCell<Message> {
    @IBOutlet weak var messageContainer: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var time: UILabel!
    
    override func initialization() {
        messageContainer.layer.cornerRadius = 20
      transform = CGAffineTransform(scaleX: 1, y: -1)
    }

    override func bind(data: Message) {
        messageLabel.text=data.message
        time.text=Date.formatDateTime(milis: data.createdAt)
    }
    
}
