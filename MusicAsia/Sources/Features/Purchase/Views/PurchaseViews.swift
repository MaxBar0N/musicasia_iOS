import UIKit
import SnapKit

class PackageItemCell: UICollectionViewCell {
    
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
        
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        priceLabel.font = .systemFont(ofSize: 24, weight: .bold)
        priceLabel.textAlignment = .center
        contentView.addSubview(priceLabel)
        
        originalPriceLabel.font = .systemFont(ofSize: 12)
        originalPriceLabel.textAlignment = .center
        contentView.addSubview(originalPriceLabel)
        
        // 钻石图标（设计稿中有个小钻石）
        diamondIcon.image = UIImage(systemName: "diamond.fill")
        diamondIcon.contentMode = .scaleAspectFit
        contentView.addSubview(diamondIcon)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.centerX.equalToSuperview()
        }
        
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        originalPriceLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(5)
            make.centerX.equalToSuperview()
        }
        
        diamondIcon.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        updateStyle()
    }
    
    func configure(with item: PackageItem) {
        titleLabel.text = item.name
        
        let priceStr = NSMutableAttributedString(string: "¥", attributes: [.font: UIFont.systemFont(ofSize: 14)])
        priceStr.append(NSAttributedString(string: "\(item.price)"))
        priceLabel.attributedText = priceStr
        
        let original = item.originalPrice
        if original > item.price {
            let attrStr = NSAttributedString(
                string: "¥\(original)",
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
        if isSelected {
            contentView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            contentView.layer.borderColor = UIColor(hex: "#16E0BF").cgColor
            titleLabel.textColor = .white
            priceLabel.textColor = .white
            diamondIcon.tintColor = UIColor(hex: "#16E0BF")
        } else {
            contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            titleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            priceLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            diamondIcon.tintColor = UIColor.white.withAlphaComponent(0.2)
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
            priceLabel.text = "\(price)元"
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
