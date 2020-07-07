//
//  ChatTableViewCell.swift
//  AgoraDemo
//
//  Created by Jonathan  Fotland on 6/11/20.
//  Copyright © 2020 Jonathan Fotland. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
