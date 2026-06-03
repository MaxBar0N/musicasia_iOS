import UIKit
import SnapKit

class PackageItemCell: UICollectionViewCell {
    
    private let bgImageView = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let originalPriceLabel = UILabel()
    private let diamondIcon = UIImageView()
    
    override var isSelected: Bool {
        didSet {
            updateStyle()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1.5
        contentView.layer.masksToBounds = true
        
        bgImageView.image = UIImage(named: "combo_item_background_image")
        bgImageView.contentMode = .scaleToFill
        contentView.addSubview(bgImageView)
        
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)
        
        priceLabel.font = .systemFont(ofSize: 24, weight: .bold)
        priceLabel.textAlignment = .center
        contentView.addSubview(priceLabel)
        
        originalPriceLabel.font = .systemFont(ofSize: 12)
        originalPriceLabel.textAlignment = .center
        contentView.addSubview(originalPriceLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-5)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        originalPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
        }
        
        updateStyle()
    }
    
    func configure(with item: PackageItem) {
        titleLabel.text = item.name
        
        let priceStr = NSMutableAttributedString(string: "¥", attributes: [.font: UIFont.systemFont(ofSize: 14)])
        priceStr.append(NSAttributedString(string: String(format: "%.2f", item.price).replacingOccurrences(of: ".00", with: "")))
        priceLabel.attributedText = priceStr
        
        let original = item.originalPrice
        if original > item.price {
            let attrStr = NSAttributedString(
                string: "¥" + String(format: "%.2f", original).replacingOccurrences(of: ".00", with: ""),
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.white.withAlphaComponent(0.5)
                ]
            )
            originalPriceLabel.attributedText = attrStr
            originalPriceLabel.isHidden = false
        } else {
            originalPriceLabel.isHidden = true
        }
    }
    
    private func updateStyle() {
        // 背景图一直显示
        bgImageView.isHidden = false
        
        if isSelected {
            contentView.backgroundColor = .clear
            contentView.layer.borderColor = UIColor(hex: "#16E0BF").cgColor
            titleLabel.textColor = .white
            priceLabel.textColor = .white
        } else {
            contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            contentView.layer.borderColor = UIColor.clear.cgColor // 未选中时去掉边框
            titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            priceLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

class BenefitRowView: UIView {
    init(benefit: PackageBenefit) {
        super.init(frame: .zero)
        
        let nameLabel = UILabel()
        nameLabel.text = benefit.name
        nameLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        nameLabel.font = .systemFont(ofSize: 14)
        addSubview(nameLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }
        
        if let desc = benefit.desc {
            let descLabel = UILabel()
            descLabel.text = desc
            descLabel.textColor = UIColor.white.withAlphaComponent(0.5)
            descLabel.font = .systemFont(ofSize: 11)
            addSubview(descLabel)
            
            descLabel.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalTo(nameLabel.snp.bottom).offset(2)
                make.bottom.equalToSuperview()
            }
        } else {
            nameLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
        
        if let price = benefit.price {
            let priceLabel = UILabel()
            priceLabel.text = "\(String(format: "%.2f", price).replacingOccurrences(of: ".00", with: ""))元"
            priceLabel.textColor = UIColor.white.withAlphaComponent(0.9)
            priceLabel.font = .systemFont(ofSize: 14)
            addSubview(priceLabel)
            
            priceLabel.snp.makeConstraints { make in
                make.right.centerY.equalToSuperview()
            }
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
