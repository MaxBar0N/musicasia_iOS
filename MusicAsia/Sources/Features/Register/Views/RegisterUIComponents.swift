import UIKit
import SnapKit

class GradientIndicatorView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gradientLayer.colors = [
            UIColor(hex: "#3CE2FF").cgColor,
            UIColor(hex: "#A89EFF").cgColor,
            UIColor(hex: "#4A68FF").cgColor
        ]
        gradientLayer.locations = [0.0, 0.5076, 1.0]
        
        // 146deg 渐变，大致为从左上到右下偏下
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1.0)
        
        layer.addSublayer(gradientLayer)
        
        // 由于高度为2，圆角设为1以达到胶囊效果，虽然 CSS 写了 8px，但在高度 2px 下，圆角最大只能是 1px。
        layer.cornerRadius = 1
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

/// 表单标题，支持红色星号必填标记
class FormTitleLabel: UILabel {
    init(title: String, isRequired: Bool = true) {
        super.init(frame: .zero)
        font = .systemFont(ofSize: 14, weight: .medium)
        
        if isRequired {
            let attrStr = NSMutableAttributedString(string: "* ", attributes: [
                .foregroundColor: UIColor.red,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ])
            attrStr.append(NSAttributedString(string: title, attributes: [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ]))
            attributedText = attrStr
        } else {
            text = title
            textColor = .white
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 底部弹出的省市级联选择器
class RegionPickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    private let regionData: [(province: String, cities: [String])] = [
        ("北京", ["东城区", "西城区", "朝阳区", "丰台区", "石景山区", "海淀区", "门头沟区", "房山区", "通州区", "顺义区", "昌平区", "大兴区", "怀柔区", "平谷区", "密云区", "延庆区"]),
        ("上海", ["黄浦区", "徐汇区", "长宁区", "静安区", "普陀区", "虹口区", "杨浦区", "闵行区", "宝山区", "嘉定区", "浦东新区", "金山区", "松江区", "青浦区", "奉贤区", "崇明区"]),
        ("天津", ["和平区", "河东区", "河西区", "南开区", "河北区", "红桥区", "东丽区", "西青区", "津南区", "北辰区", "武清区", "宝坻区", "滨海新区", "宁河区", "静海区", "蓟州区"]),
        ("重庆", ["万州区", "涪陵区", "渝中区", "大渡口区", "江北区", "沙坪坝区", "九龙坡区", "南岸区", "北碚区", "綦江区", "大足区", "渝北区", "巴南区", "黔江区", "长寿区", "江津区", "合川区", "永川区", "南川区", "璧山区", "铜梁区", "潼南区", "荣昌区", "开州区", "梁平区", "武隆区"]),
        ("河北", ["济南市", "青岛市", "淄博市", "枣庄市", "东营市", "烟台市", "潍坊市", "济宁市", "泰安市", "威海市", "日照市", "临沂市", "德州市", "聊城市", "滨州市", "菏泽市"]),
        ("山西", ["太原市", "大同市", "阳泉市", "长治市", "晋城市", "朔州市", "晋中市", "运城市", "忻州市", "临汾市", "吕梁市"]),
        ("辽宁", ["沈阳市", "大连市", "鞍山市", "抚顺市", "本溪市", "丹东市", "锦州市", "营口市", "阜新市", "辽阳市", "盘锦市", "铁岭市", "朝阳市", "葫芦岛市"]),
        ("吉林", ["沈阳市", "大连市", "鞍山市", "抚顺市", "本溪市", "丹东市", "锦州市", "营口市", "阜新市", "辽阳市", "盘锦市", "铁岭市", "朝阳市", "葫芦岛市"]),
        ("黑龙江", ["长春市", "吉林市", "四平市", "辽源市", "通化市", "白山市", "松原市", "白城市", "延边朝鲜族自治州"]),
        ("江苏", ["南京市", "无锡市", "徐州市", "常州市", "苏州市", "南通市", "连云港市", "淮安市", "盐城市", "扬州市", "镇江市", "泰州市", "宿迁市"]),
        ("浙江", ["杭州市", "宁波市", "温州市", "嘉兴市", "湖州市", "绍兴市", "金华市", "衢州市", "舟山市", "台州市", "丽水市"]),
        ("安徽", ["合肥市", "芜湖市", "蚌埠市", "淮南市", "马鞍山市", "淮北市", "铜陵市", "安庆市", "黄山市", "滁州市", "阜阳市", "宿州市", "六安市", "亳州市", "池州市", "宣城市"]),
        ("福建", ["福州市", "厦门市", "莆田市", "三明市", "泉州市", "漳州市", "南平市", "龙岩市", "宁德市"]),
        ("江西", ["南昌市", "景德镇市", "萍乡市", "九江市", "新余市", "鹰潭市", "赣州市", "吉安市", "宜春市", "抚州市", "上饶市"]),
        ("山东", ["济南市", "青岛市", "淄博市", "枣庄市", "东营市", "烟台市", "潍坊市", "济宁市", "泰安市", "威海市", "日照市", "临沂市", "德州市", "聊城市", "滨州市", "菏泽市"]),
        ("河南", ["郑州市", "开封市", "洛阳市", "平顶山市", "安阳市", "鹤壁市", "新乡市", "焦作市", "濮阳市", "许昌市", "漯河市", "三门峡市", "南阳市", "商丘市", "信阳市", "周口市", "驻马店市"]),
        ("湖北", ["武汉市", "黄石市", "十堰市", "宜昌市", "襄阳市", "鄂州市", "荆门市", "孝感市", "荆州市", "黄冈市", "咸宁市", "随州市"]),
        ("湖南", ["长沙市", "株洲市", "湘潭市", "衡阳市", "邵阳市", "岳阳市", "常德市", "张家界市", "益阳市", "郴州市", "永州市", "怀化市", "娄底市"]),
        ("广东", ["广州市", "韶关市", "深圳市", "珠海市", "汕头市", "佛山市", "江门市", "湛江市", "茂名市", "肇庆市", "惠州市", "梅州市", "汕尾市", "河源市", "阳江市", "清远市", "东莞市", "中山市", "潮州市", "揭阳市", "云浮市"]),
        ("海南", ["广州市", "韶关市", "深圳市", "珠海市", "汕头市", "佛山市", "江门市", "湛江市", "茂名市", "肇庆市", "惠州市", "梅州市", "汕尾市", "河源市", "阳江市", "清远市", "东莞市", "中山市", "潮州市", "揭阳市", "云浮市"]),
        ("四川", ["成都市", "自贡市", "攀枝花市", "泸州市", "德阳市", "绵阳市", "广元市", "遂宁市", "内江市", "乐山市", "南充市", "眉山市", "宜宾市", "广安市", "达州市", "雅安市", "巴中市", "资阳市"]),
        ("贵州", ["贵阳市", "六盘水市", "遵义市", "安顺市", "毕节市", "铜仁市", "黔西南布依族苗族自治州", "黔东南苗族布依族自治州", "黔南布依族苗族自治州"]),
        ("云南", ["昆明市", "曲靖市", "玉溪市", "保山市", "昭通市", "丽江市", "普洱市", "临沧市"]),
        ("陕西", ["西安市", "铜川市", "宝鸡市", "咸阳市", "渭南市", "延安市", "汉中市", "榆林市", "安康市", "商洛市"]),
        ("甘肃", ["昆明市", "曲靖市", "玉溪市", "保山市", "昭通市", "丽江市", "普洱市", "临沧市"]),
        ("青海", ["西安市", "铜川市", "宝鸡市", "咸阳市", "渭南市", "延安市", "汉中市", "榆林市", "安康市", "商洛市"]),
        ("台湾", ["台北市", "高雄市", "基隆市", "台中市", "台南市", "新竹市", "嘉义市"]),
        ("内蒙古", ["哈尔滨市", "齐齐哈尔市", "鸡西市", "鹤岗市", "双鸭山市", "大庆市", "伊春市", "佳木斯市", "七台河市", "牡丹江市", "黑河市", "绥化市", "大兴安岭地区"]),
        ("广西", ["南宁市", "柳州市", "桂林市", "梧州市", "北海市", "防城港市", "钦州市", "贵港市", "玉林市", "百色市", "贺州市", "河池市", "来宾市", "崇左市"]),
        ("西藏", ["西宁市", "海东市", "海北藏族自治州", "黄南藏族自治州", "海南藏族自治州", "果洛藏族自治州", "玉树藏族自治州", "海西蒙古族藏族自治州"]),
        ("宁夏", ["银川市", "石嘴山市", "吴忠市", "固原市", "中卫市"]),
        ("新疆", ["乌鲁木齐市", "克拉玛依市", "吐鲁番市", "哈密市", "昌吉回族自治州", "博尔塔拉蒙古自治州", "巴音郭楞蒙古自治州", "阿克苏地区", "克孜勒苏柯尔克孜自治州", "喀什地区", "和田地区", "伊犁哈萨克自治州", "塔城地区", "阿勒泰地区"]),
        ("香港", ["香港岛", "九龙", "新界"]),
        ("澳门", ["香港岛", "九龙", "新界"])
    ]
    
    private var selectedProvinceIndex = 0
    private var selectedCityIndex = 0
    
    var onConfirm: ((String, String) -> Void)?
    
    private let backgroundView = UIView()
    private let containerView = UIView()
    private let pickerView = UIPickerView()
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backgroundView.alpha = 0
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        backgroundView.addGestureRecognizer(tap)
        
        containerView.backgroundColor = UIColor(hex: "#1A1B2C") // 适配深色主题
        containerView.layer.cornerRadius = 16
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        addSubview(containerView)
        
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        containerView.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        cancelBtn.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        toolbar.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.setTitleColor(UIColor(hex: "#16E0BF"), for: .normal)
        confirmBtn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        toolbar.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.backgroundColor = .clear
        containerView.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(200)
        }
    }
    
    func show(in view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 初始状态放在屏幕底部之外
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
        }
        self.layoutIfNeeded()
        
        // 动画弹出
        containerView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = 1
            self.layoutIfNeeded()
        }
    }
    
    @objc private func dismiss() {
        containerView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.alpha = 0
            self.layoutIfNeeded()
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func confirmAction() {
        let province = regionData[selectedProvinceIndex].province
        let city = regionData[selectedProvinceIndex].cities[selectedCityIndex]
        onConfirm?(province, city)
        dismiss()
    }
    
    // MARK: - UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return regionData.count
        } else {
            return regionData[selectedProvinceIndex].cities.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title: String
        if component == 0 {
            title = regionData[row].province
        } else {
            title = regionData[selectedProvinceIndex].cities[row]
        }
        return NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedProvinceIndex = row
            selectedCityIndex = 0
            pickerView.reloadComponent(1)
            pickerView.selectRow(0, inComponent: 1, animated: true)
        } else {
            selectedCityIndex = row
        }
    }
}

/// 基础输入框组件 (标题 + 输入框)
class FormInputField: UIView {
    let titleLabel: FormTitleLabel
    let textField = CustomTextField()
    
    init(title: String, placeholder: String, isRequired: Bool = true) {
        titleLabel = FormTitleLabel(title: title, isRequired: isRequired)
        super.init(frame: .zero)
        
        textField.setCustomPlaceholder(placeholder)
        
        addSubview(titleLabel)
        addSubview(textField)
        
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 验证码输入组件 (标题 + 输入框 + 发送按钮)
class FormCodeField: UIView {
    let titleLabel: FormTitleLabel
    let textField = CustomTextField()
    let sendButton = GradientButton()
    
    init(title: String, placeholder: String, isRequired: Bool = true) {
        titleLabel = FormTitleLabel(title: title, isRequired: isRequired)
        super.init(frame: .zero)
        
        textField.setCustomPlaceholder(placeholder)
        sendButton.setTitle("发送", for: .normal)
        
        addSubview(titleLabel)
        addSubview(textField)
        addSubview(sendButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.bottom.equalToSuperview()
            make.right.equalTo(sendButton.snp.left).offset(-10)
            make.height.equalTo(40)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 下拉选择组件 (标题 + 两个下拉框)
class FormDropdownField: UIView {
    let titleLabel: FormTitleLabel
    let provinceButton = UIButton(type: .system)
    let cityButton = UIButton(type: .system)
    
    var onProvinceTapped: (() -> Void)?
    var onCityTapped: (() -> Void)?
    
    init(title: String, isRequired: Bool = true) {
        titleLabel = FormTitleLabel(title: title, isRequired: isRequired)
        super.init(frame: .zero)
        
        setupButton(provinceButton, placeholder: "请选择省份")
        setupButton(cityButton, placeholder: "请选择城市")
        
        provinceButton.addTarget(self, action: #selector(provinceAction), for: .touchUpInside)
        cityButton.addTarget(self, action: #selector(cityAction), for: .touchUpInside)
        
        addSubview(titleLabel)
        
        let stackView = UIStackView(arrangedSubviews: [provinceButton, cityButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        addSubview(stackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(40) // 与其他输入框高度一致
        }
    }
    
    private func setupButton(_ button: UIButton, placeholder: String) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
        button.setTitle(placeholder, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        
        // 文字靠左，左侧留出间距
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 30)
        
        // 独立添加右侧箭头，确保绝对靠右展示
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: symbolConfig))
        arrowImageView.tintColor = .white
        arrowImageView.isUserInteractionEnabled = false // 避免拦截点击
        
        button.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    @objc private func provinceAction() {
        onProvinceTapped?()
    }
    
    @objc private func cityAction() {
        onCityTapped?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 图片上传组件
class FormImageUploadView: UIView {
    let titleLabel: FormTitleLabel
    private let contentContainer = UIView()
    var maxCount: Int
    private let uploadBtn = UIButton(type: .system)
    
    private(set) var images: [UIImage] = [] {
        didSet {
            reloadImages()
        }
    }
    
    var onUploadTapped: (() -> Void)?
    
    init(title: String, subtitle: String? = nil, maxCount: Int = 1) {
        titleLabel = FormTitleLabel(title: title)
        self.maxCount = maxCount
        super.init(frame: .zero)
        
        addSubview(titleLabel)
        
        if let subtitle = subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            subtitleLabel.font = .systemFont(ofSize: 12)
            addSubview(subtitleLabel)
            
            titleLabel.snp.makeConstraints { make in
                make.top.left.equalToSuperview()
            }
            subtitleLabel.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.left.equalTo(titleLabel.snp.right).offset(8)
            }
        } else {
            titleLabel.snp.makeConstraints { make in
                make.top.left.equalToSuperview()
            }
        }
        
        addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
        
        setupUploadBtn()
        reloadImages()
    }
    
    private func setupUploadBtn() {
        uploadBtn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        uploadBtn.layer.cornerRadius = 8
        uploadBtn.setImage(UIImage(systemName: "photo.badge.plus"), for: .normal)
        uploadBtn.tintColor = .white
        uploadBtn.addTarget(self, action: #selector(uploadAction), for: .touchUpInside)
    }
    
    func addImages(_ newImages: [UIImage]) {
        let spaceLeft = maxCount - images.count
        guard spaceLeft > 0 else { return }
        let imagesToAdd = Array(newImages.prefix(spaceLeft))
        images.append(contentsOf: imagesToAdd)
    }
    
    func addImage(_ image: UIImage) {
        addImages([image])
    }
    
    private func reloadImages() {
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        
        var items: [UIView] = []
        
        for (index, image) in images.enumerated() {
            let container = UIView()
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            container.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // 添加点击预览手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.tag = index
            imageView.addGestureRecognizer(tapGesture)
            
            let deleteBtn = UIButton(type: .custom)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            deleteBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
            deleteBtn.tintColor = .red
            deleteBtn.backgroundColor = .white
            deleteBtn.layer.cornerRadius = 9
            deleteBtn.tag = index
            deleteBtn.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)
            
            container.addSubview(deleteBtn)
            deleteBtn.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.right.equalToSuperview().offset(-4)
                make.width.height.equalTo(18)
            }
            
            items.append(container)
        }
        
        if images.count < maxCount {
            items.append(uploadBtn)
        }
        
        var rowFirstItem: UIView? = nil
        var previousItem: UIView? = nil
        let columns = 2
        let spacing: CGFloat = 10
        
        for (index, item) in items.enumerated() {
            contentContainer.addSubview(item)
            
            item.snp.makeConstraints { make in
                // 严格按照设计稿：一行两个，尺寸 120 * 60
                make.width.equalTo(120)
                make.height.equalTo(60)
                
                if index % columns == 0 {
                    make.left.equalToSuperview()
                    if let rowFirst = rowFirstItem {
                        make.top.equalTo(rowFirst.snp.bottom).offset(spacing)
                    } else {
                        make.top.equalToSuperview()
                    }
                    rowFirstItem = item
                } else {
                    if let prev = previousItem {
                        make.left.equalTo(prev.snp.right).offset(spacing)
                        make.top.equalTo(prev.snp.top)
                    }
                }
                
                if index == items.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
            previousItem = item
        }
    }
    
    @objc private func deleteTapped(_ sender: UIButton) {
        let index = sender.tag
        guard let vc = self.parentViewController else { return }
        
        let alert = UIAlertController(title: "删除照片", message: "确定要删除这张照片吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            if index >= 0 && index < self.images.count {
                self.images.remove(at: index)
            }
        }))
        vc.present(alert, animated: true, completion: nil)
    }
    
    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView, let image = imageView.image else { return }
        
        let window = UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first
        guard let validWindow = window else { return }
        
        let backgroundView = UIView(frame: validWindow.bounds)
        backgroundView.backgroundColor = .black
        backgroundView.alpha = 0
        
        let previewImageView = UIImageView(image: image)
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.frame = backgroundView.bounds
        previewImageView.isUserInteractionEnabled = true
        
        backgroundView.addSubview(previewImageView)
        
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissPreview(_:)))
        backgroundView.addGestureRecognizer(dismissTap)
        
        validWindow.addSubview(backgroundView)
        
        UIView.animate(withDuration: 0.3) {
            backgroundView.alpha = 1
        }
    }
    
    @objc private func dismissPreview(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        UIView.animate(withDuration: 0.3, animations: {
            view.alpha = 0
        }) { _ in
            view.removeFromSuperview()
        }
    }
    
    @objc private func uploadAction() {
        onUploadTapped?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 协议复选框
class AgreementCheckboxView: UIView {
    let checkboxButton = UIButton(type: .custom)
    let agreementLabel = UILabel()
    
    var isChecked: Bool = false {
        didSet {
            updateState()
        }
    }
    
    // 添加初始化方法以支持自定义文本
    init(text: String = "注册代表同意并接受 ", linkText: String = "《平台注册规则》") {
        super.init(frame: .zero)
        setupUI(text: text, linkText: linkText)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI(text: "注册代表同意并接受 ", linkText: "《平台注册规则》")
    }
    
    private func setupUI(text: String, linkText: String) {
        checkboxButton.addTarget(self, action: #selector(toggleCheck), for: .touchUpInside)
        
        let attrStr = NSMutableAttributedString(string: text, attributes: [
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 12)
        ])
        attrStr.append(NSAttributedString(string: linkText, attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]))
        agreementLabel.attributedText = attrStr
        
        addSubview(checkboxButton)
        addSubview(agreementLabel)
        
        checkboxButton.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        agreementLabel.snp.makeConstraints { make in
            make.left.equalTo(checkboxButton.snp.right).offset(8)
            make.centerY.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        
        updateState()
    }
    
    private func updateState() {
        // "circle" 为空心圆圈, "circle.inset.filled" 为内部带圆点的圆圈
        let imageName = isChecked ? "circle.inset.filled" : "circle"
        checkboxButton.setImage(UIImage(systemName: imageName), for: .normal)
        // 无论选中与否都保持白色
        checkboxButton.tintColor = .white
    }
    
    @objc private func toggleCheck() {
        isChecked.toggle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
