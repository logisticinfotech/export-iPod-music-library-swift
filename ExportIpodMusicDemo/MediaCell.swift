
//
//  MediaCell.swift
//  ExportIpodMusicDemo
//
//  Created by Vishal on 25/03/19.
//  Copyright © 2019 Matt Neuburg. All rights reserved.
//

import UIKit

class MediaCell: UITableViewCell {

    @IBOutlet weak var lblSizeName: UILabel!
    @IBOutlet weak var lblMediaName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
