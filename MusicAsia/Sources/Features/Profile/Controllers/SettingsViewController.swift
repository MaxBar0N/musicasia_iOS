import UIKit
import SnapKit
import Kingfisher

class SettingsViewController: BaseViewController {
    
    // MARK: - UI Components
    private let avatarImg = UIImageView()
    private let nameLabel = UILabel()
    private let vipLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "个人中心"
        setupUI()
        fetchUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Data
    private func fetchUserInfo() {
        ProfileAPI.getMeInfo(pageNum: 1, pageSize: 1) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let pageResponse):
                    guard let data = pageResponse.data else { return }
                    
                    // Name
                    let finalName: String
                    if let name = data.name, !name.isEmpty {
                        finalName = name
                    } else if let phone = data.phone, !phone.isEmpty {
                        if phone.count == 11 {
                            let start = phone.index(phone.startIndex, offsetBy: 3)
                            let end = phone.index(phone.endIndex, offsetBy: -4)
                            finalName = phone[..<start] + "****" + phone[end...]
                        } else {
                            finalName = phone
                        }
                    } else {
                        finalName = "用户"
                    }
                    self.nameLabel.text = finalName
                    
                    // VIP
                    if let endTime = data.endTime, !endTime.isEmpty {
                        self.vipLabel.text = "会员到期：\(endTime)"
                    } else {
                        self.vipLabel.text = "会员到期：---"
                    }
                    
                    // Avatar
                    var logoUrl = data.logo ?? ""
                    logoUrl = logoUrl.replacingOccurrences(of: "\\", with: "/")
                    if logoUrl.contains("localhost") || logoUrl.contains("127.0.0.1") || logoUrl.contains("192.168.") {
                        if let pathIndex = logoUrl.range(of: "/", options: [], range: logoUrl.index(logoUrl.startIndex, offsetBy: 8)..<logoUrl.endIndex)?.lowerBound {
                            logoUrl = String(logoUrl[pathIndex...])
                        }
                    }
                    if !logoUrl.isEmpty && !logoUrl.hasPrefix("http") {
                        logoUrl = "http://47.243.180.202:48080" + (logoUrl.hasPrefix("/") ? "" : "/") + logoUrl
                    }
                    logoUrl = logoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? logoUrl
                    
                    let placeholder = UIImage(systemName: "person.crop.square.fill")
                    if let url = URL(string: logoUrl), !logoUrl.isEmpty {
                        self.avatarImg.kf.setImage(with: url, placeholder: placeholder)
                    } else {
                        self.avatarImg.image = placeholder
                        self.avatarImg.tintColor = .white
                    }
                    
                case .failure(let error):
                    print("获取个人信息失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 1. 顶部卡片 (复用个人信息展示)
        let profileCard = UIImageView()
        profileCard.image = UIImage(named: "my_banner_bg_image")
        profileCard.contentMode = .scaleAspectFill
        profileCard.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        profileCard.layer.cornerRadius = 15
        profileCard.clipsToBounds = true
        profileCard.isUserInteractionEnabled = true
        view.addSubview(profileCard)
        
        profileCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }
        
        avatarImg.layer.cornerRadius = 10
        avatarImg.clipsToBounds = true
        avatarImg.contentMode = .scaleAspectFill
        avatarImg.image = UIImage(systemName: "person.crop.square.fill")
        avatarImg.tintColor = .white
        profileCard.addSubview(avatarImg)
        
        avatarImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        nameLabel.text = "加载中..."
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        profileCard.addSubview(nameLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImg.snp.right).offset(15)
            make.top.equalTo(avatarImg).offset(5)
        }
        
        vipLabel.text = "会员到期：..."
        vipLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        vipLabel.font = .systemFont(ofSize: 12)
        profileCard.addSubview(vipLabel)
        
        vipLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
        }
        
        // 2. 协议列表菜单
        let userAgreementBtn = createMenuButton(title: "用户服务协议")
        userAgreementBtn.addTarget(self, action: #selector(handleUserAgreement), for: .touchUpInside)
        
        let privacyBtn = createMenuButton(title: "隐私协议")
        privacyBtn.addTarget(self, action: #selector(handlePrivacyPolicy), for: .touchUpInside)
        
        view.addSubview(userAgreementBtn)
        userAgreementBtn.snp.makeConstraints { make in
            make.top.equalTo(profileCard.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        view.addSubview(privacyBtn)
        privacyBtn.snp.makeConstraints { make in
            make.top.equalTo(userAgreementBtn.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        // 3. 底部退出注销按钮
        let logoutBtn = GradientButton()
        logoutBtn.setTitle("快速退出", for: .normal)
        logoutBtn.layer.cornerRadius = 25
        logoutBtn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        view.addSubview(logoutBtn)
        
        logoutBtn.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(50)
        }
        
        let deleteAccountBtn = UIButton(type: .system)
        deleteAccountBtn.setTitle("注销用户", for: .normal)
        deleteAccountBtn.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        deleteAccountBtn.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        deleteAccountBtn.layer.cornerRadius = 25
        deleteAccountBtn.addTarget(self, action: #selector(handleDeleteAccount), for: .touchUpInside)
        view.addSubview(deleteAccountBtn)
        
        deleteAccountBtn.snp.makeConstraints { make in
            make.top.equalTo(logoutBtn.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(50)
        }
    }
    
    private func createMenuButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15)
        btn.addSubview(titleLabel)
        
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor.white.withAlphaComponent(0.5)
        btn.addSubview(arrow)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(16)
        }
        
        return btn
    }
    
    // MARK: - Actions
    @objc private func handleUserAgreement() {
        let agreementVC = AgreementViewController()
        agreementVC.agreementTitle = "服务协议"
        agreementVC.contentTitleText = "唱享视界硬件版用户服务使用协议"
        agreementVC.contentText = """
        1. 接受条款
        唱享视界根据以下服务条款为您提供服务。这些条款可由唱享视界随时更新，且无须另行通知。唱享视界硬件版用户服务使用协议（以下简称“使用协议”）一旦发生变动，唱享视界将在网页上公布修改内容。修改后的使用协议一旦在网页上公布即有效代替原来的使用协议。此外，当您使用唱享视界特殊服务时，您和唱享视界应遵守唱享视界随时公布的与该服务相关的指引和规则。前述所有的指引和规则，均构成本使用协议的一部分。
        您在使用唱享视界提供的各项服务之前，应仔细阅读本使用协议。如您不同意本使用协议及/或随时对其的修改，请您立即停止使用唱享视界所提供的全部服务；您一旦使用唱享视界服务，即视为您已了解并完全同意本使用协议各项内容，包括唱享视界对使用协议随时所做的任何修改，并成为唱享视界用户（以下简称“用户”）。
        
        2. 服务说明
        唱享视界向用户提供唱享视界硬件版音乐、影视、卡拉OK技术服务（以下简称“本服务”），用户可以在唱享视界硬件版中通过硬件设备及本软件实现视听、录音并保存上传自己的作品，但不包含相应版权责任，版权由内容版权方提供并负责，本软件只提供相应技术服务。除非本使用协议另有其他明示规定，增加或强化目前本服务的任何新功能，包括所推出的新产品，均受到本使用协议之规范。
        您了解并同意，本服务仅依其当前所呈现的状况提供，对于任何用户信息或个人化设定之时效、删除、传递错误、未予储存或其他任何问题，唱享视界均不承担任何责任。唱享视界保留不经事先通知为维修保养、升级或其他目的暂停本服务任何部分的权利，并无需承担任何责任。您所购买的唱享视界硬件版会员不包含家用计算机、车载卡拉OK、卡拉OK经营场所点唱设备、单机版卡拉OK点播产品、迷你歌咏亭等设备的使用。
        
        3. 遵守法律
        您同意遵守中华人民共和国相关法律法规的所有规定，并对以任何方式使用本服务的任何行为及其结果承担全部责任。如您的行为违反国家法律和法规的任何规定，有可能构成犯罪的，将被追究刑事责任，并由您承担全部法律责任。
        同时如果唱享视界有理由认为您的任何行为，包括但不限于您的任何言论和其它行为违反或可能违反国家法律和法规的任何规定，唱享视界可在任何时候不经任何事先通知终止向您提供服务并删除相关言论、音视频等内容，并无需承担任何责任。
        
        4. 您的注册义务
        您注册成功后，本产品将为您提供一个帐号（下称“帐号”）。您在申请使用本产品服务时，应当向我们提供真实、准确的个人资料，以完成实名认证；您应确保开通本服务所提供的姓名和身份证号等信息为本人所有，并授权我们通过依法成立的合法采集机构或认证机构对您所提供的姓名和身份证号等信息的真实性和有效性进行认证。如个人资料有任何变动，您须及时在本产品中予以更新。
        为了能使用本服务全部功能，您同意以下事项：依本服务注册提示请您填写正确的注册手机号、密码和帐号名，并确保今后更新的手机号、帐号名、头像等资料的有效性和合法性。若您提供任何违法、不道德或唱享视界认为不适合在唱享视界上展示的资料；或者唱享视界有理由怀疑你的资料属于程序或恶意操作，唱享视界有权暂停或终止您的帐号，并拒绝您于现在和未来使用本服务之全部或任何部分。
        
        5. 用户帐号、密码及安全
        完成本服务的注册程序并成功注册之后，您可使用您的手机号和验证码，登录到您在唱享视界的帐号（下称“帐号”）。保护您的帐号安全，是您的责任。您应对所有使用您的密码及帐号（包括他人使用您的密码及帐号）的活动负完全的责任。
        您同意：
        1）您的唱享视界帐号遭到未获授权的使用，或者发生其他任何安全问题时，您将立即通知唱享视界；
        2）如果您未保管好自己的帐号和密码，因此而产生的任何损失或损害，唱享视界无法也不承担任何责任；
        3）每个用户都要对其帐号中的所有行为和事件负全责。如果因您未保管好自己的帐号和密码而对您、唱享视界或第三方造成的损害，您将负全部责任。因唱享视界故意或者重大过失导致的损害除外；
        4）如用户在申请开通服务后连续六个月未实际使用，则唱享视界有权回收用户昵称。
        
        6. 用户帐号注销
        为保障您注销唱享视界账号的权利，我们在产品设计中为您提供了相应的操作设置，您可参考下面的指引进行操作。
        （1）卸载软件注销唱享视界账号后，除法律法规另有规定外，您在唱享视界账号下的个人信息将进行匿名化处理，且此前已关联该唱享视界账号的相关产品与服务将不再关联。在您注销账号之后，您将放弃就该账号享有的权益，唱享视界也将停止为您提供相应的产品或服务。该唱享视界账号一旦注销完成，将无法恢复，请您谨慎操作。
        
        7. 唱享视界用户隐私政策
        您提供的登记资料及唱享视界保留的有关您的若干其他资料将受到中国有关隐私的法律和本公司《用户隐私政策》之规范。
        
        8. 提供者之责任
        根据有关法律法规，唱享视界在此郑重提请您注意，任何经由本服务而发布、上传的文字、资讯、资料、音乐、照片、图形、视讯、信息或其它资料（以下简称“内容 ”），无论系公开还是私下传送，均由内容提供者承担责任。唱享视界仅为用户提供技术服务，无法控制经由本服务传送之内容，因此不保证内容的正确性、完整性、合法性或品质。您已预知使用本服务时，可能会接触到令人不快、不适当或令人厌恶之内容。在任何情况下，唱享视界均不为任何内容负责，但唱享视界有权依法停止传输任何前述内容并采取相应行动，包括但不限于暂停用户使用本服务的全部或部分，删除相关内容，保存有关记录，并向有关机关报告。
        用户在录音时，如果使用其他的配乐、伴奏、照片等可能涉及第三方版权及其他权利的内容配合录制并上传，则用户需要确认对该配乐和伴奏、照片等享有相应使用权，否则唱享视界可删除您上传的内容。
        
        9. 用户行为
        用户同意将不会利用本服务进行任何违法或不正当的活动，包括但不限于下列行为∶
        1）发布或以其他方式传送含有下列内容之一的信息：
        * 反对宪法所确定的基本原则的；
        * 危害国家安全，泄露国家秘密，颠覆国家政权，破坏国家统一的；
        * 损害国家荣誉和利益的；
        * 煽动民族仇恨、民族歧视、破坏民族团结的；
        * 破坏国家宗教政策，宣扬邪教和封建迷信的；
        * 散布谣言，扰乱社会秩序，破坏社会稳定的；
        * 散布淫秽、色情、赌博、暴力、凶杀、恐怖或者教唆犯罪的；
        * 侮辱或者诽谤他人，侵害他人合法权利的；
        * 含有虚假、诈骗、有害、胁迫、侵害他人隐私、骚扰、侵害、中伤、粗俗、猥亵、或其他道德上令人反感的内容；
        * 含有中国法律、法规、规章、条例以及任何具有法律效力之规范所限制或禁止的其他内容的；
        * 含有唱享视界认为不适合在唱享视界展示的内容；
        2）以任何方式危害他人的合法权益；
        3）冒充其他任何人或机构，或以虚伪不实的方式陈述或谎称与任何人或机构有关；
        4）将依据任何法律或合约或法定关系（例如由于雇佣关系和依据保密合约所得知或揭露之内部资料、专属及机密资料）知悉但无权传送之任何内容加以发布、发送电子邮件或以其他方式传送；
        5）将侵害他人着作权、专利权、商标权、商业秘密、或其它专属权利（以下简称“专属权利”）之内容加以发布或以其他方式传送；
        6）将任何广告信函、促销资料、垃圾邮件、滥发信件、连锁信件、直销或其他任何形式的劝诱资料加以发布、发送或以其他方式传送；
        7）将设计目的在于干扰、破坏或限制任何计算机软件、硬件或通讯设备功能之计算机病毒（包括但不限于木马程序（trojan horses）、蠕虫（worms）、定时炸弹、删除蝇（cancelbots）（以下简称“病毒”）或其他计算机代码、档案和程序之任何资料，加以发布、发送或以其他方式传送；
        8）干扰或破坏本服务或与本服务相连线之服务器和网络，或违反任何关于本服务连线网络之规定、程序、政策或规范；
        9）跟踪、人肉搜索或以其他方式骚扰他人；
        10）故意或非故意地违反任何适用的当地、国家法律，以及任何具有法律效力的规则；
        11）未经合法授权而截获、篡改、收集、储存或删除他人个人信息、站内邮件或其他数据资料，或将获知的此类资料用于任何非法或不正当目的。
        
        您已认可唱享视界未对用户的使用行为进行全面控制，您使用任何内容时，包括依赖前述内容之正确性、完整性、合法性、或实用性时，您同意将自行加以判断并承担所有风险，而不依赖于唱享视界。但唱享视界依其自行之考虑，拒绝和删除可经由本服务提供之违反本条款的或其他引起唱享视界反感的任何内容。您了解并同意，唱享视界依据法律法规的要求，或基于诚信为了以下目的或在合理必要范围内，认定必须将内容加以保存或揭露时，得加以保存或揭露：a）遵守法律程序；b）执行本使用协议；c）回应任何第三人提出的权利主张；d）保护唱享视界、其用户及公众之权利、财产或个人安全；e）其他唱享视界认为有必要的情况。
        
        10. 国际使用之特别警告
        您已了解国际互联网的无国界性，同意遵守当地所有关于网上行为及内容之法律法规。您特别同意遵守有关从中国或您所在国家或地区输出信息之传输的所有适用法律法规。
        
        11. 在唱享视界发布的公开信息
        1）在本使用协议中，“本服务公开使用区域”系指一般公众可以使用的区域；
        2）用户在唱享视界硬件版上传或发布的内容，用户应保证其为着作权人或已取得合法授权，并且该内容不会侵犯任何第三方的合法权益，用户同意授予唱享视界所有上述内容在全球范围内的免费、不可撤销的、永久的、可再许可的独家使用权许可 ，据该许可唱享视界将有权以复制、广播、汇编、网络传播及其他不为法律所禁止的方式使用前述内容。
        
        12. 赔偿
        由于您通过本服务提供、发布或传送之内容、您与本服务连线、您违反本使用协议、或您侵害他人任何权利因而衍生或导致任何第三人提出任何索赔或请求，包括合理的律师费，您同意赔偿唱享视界及其子公司、关联企业、高级职员、代理人、品牌共有人或其他合作伙伴及员工，并使其免受损害，并承担由此引发的全部法律责任。如果唱享视界及其子公司、关联企业、高级职员、代理人、品牌共有人或其他合作伙伴及员工因您的侵权或者其他违法行为向第三人承担责任的，则唱享视界及其子公司、关联企业、高级职员、代理人、品牌共有人或其他合作伙伴及员工承担责任后有权全额向您追偿。
        
        13. 复制、拷贝、出售、转售等的规定
        您同意不对本服务任何部分或本服务所使用或获得的内容，进行复制、拷贝、出售、转售或用于任何其他商业目的。
        
        14. 关于使用及储存之一般措施
        您承认关于本服务的使用唱享视界有权制订一般措施及限制，包含但不限于本服务将保留所发布内容或其他发布内容之最长期间，以及一定期间内您使用本服务之次数上限（及每次使用时间之上限）。通过本服务发布或传送之任何信息、通讯资料和其他内容，如被删除或未予储存，您同意唱享视界无须承担任何责任。您也同意，唱享视界有权依其自行之考虑，不论通知与否，随时变更这些一般措施及限制。
        
        15. 服务之修改
        唱享视界有权于任何时间暂时或永久修改或终止本服务（或其任何部分），且无论通知与否。您同意对于本服务所作的任何修改、暂停或终止，唱享视界对您和任何第三人均无需承担任何责任。
        
        16. 终止服务
        您同意唱享视界基于其自行之考虑，因任何理由，包含但不限于缺乏使用，或唱享视界认为您已经违反本使用协议的文字及精神，终止您的帐号或本服务之使用（或服务之任何部分），并将您在本服务内的任何内容加以移除并删除。您同意依本使用协议任何规定提供本服务，无需进行事先通知即可中断或终止，您承认并同意，唱享视界可立即关闭或删除您的帐号及您帐号中所有相关信息及文件，及/或禁止继续使用前述文件或本服务。此外，您同意若本服务之使用被中断或终止或您的帐号及相关信息和文件被关闭或删除，唱享视界对您或任何第三人均不承担任何责任。
        
        17. 与广告商及其他第三方进行交易
        您通过本网站与广告商及其他第三方进行任何形式的通讯或商业往来，或参与促销活动，包含相关商品或服务之付款及交付，以及达成的其他任何相关条款、条件、保证或声明，完全为您与广告商及其他第三方之间之行为。您因前述任何交易或前述广告商及其他第三方而遭受的任何性质的损失或损害，唱享视界对此不负任何法律责任，法律法规另有规定的除外。
        
        18. 唱享视界之专属权利
        您了解并同意，本服务及本服务所使用之相关软件（以下简称“软件”）含有受到相关知识产权及其它法律保护之专有保密资料。您也了解并同意，经由本服务或广告商向您呈现之赞助广告或信息所包含之内容，亦受到着作权、商标权、服务商标、专利权或其它专属权利之法律保护。未经唱享视界或广告商明示授权，您不得修改、出租、出借、出售、散布本服务或软件之任何部份或全部，或据以制作衍生着作，或使用擅自修改后的软件，包括但不限于为了未经授权而使用本服务之目的。
        唱享视界仅授予您个人、不可移转及非专属之使用权，使您不得于指定硬件产品使用其软件之目的码，但您不得（并不得允许任何第三人）复制、修改、创作衍生着作、进行还原工程、反向组译，或以其他方式发现原始码，或出售、转让、再授权或提供软件设定担保，或以其他方式移转软件之任何权利。您同意将通过由唱享视界所提供的界面而非任何其它途径使用本服务。
        
        19. 担保与保证
        您明确了解并同意∶
        1）本使用协议的任何规定不会免除唱享视界对造成您人身伤害的、或因故意或重大过失造成您财产损失的任何责任；
        2）您使用本服务之风险由您个人负担。本服务系依“现状”及“现有”基础提供。唱享视界对本服务不提供任何明示或默示的担保或保证，包含但不限于商业适售性、特定目的之适用性及未侵害他人权利等担保或保证；
        3）唱享视界不保证以下事项∶
        * 本服务将符合您的要求；
        * 本服务将不受干扰、及时提供、安全可靠或不会出错；
        * 使用本服务取得之结果正确可靠；
        * 您经由本服务购买或取得之任何产品、服务、资讯或其他信息将符合您的期望；
        4）是否使用本服务下载或取得任何资料应由您自行考虑且自负风险，因任何资料之下载而导致的您硬件系统之任何损坏或数据流失等后果，由您自行承担；
        5）您自唱享视界或经由本服务取得的任何建议或信息，无论是书面或口头形式，除非本使用协议有明确规定，将不构成本使用协议以外之任何保证。
        
        20. 责任限制
        您明确了解并同意，基于以下原因而造成的，包括但不限于经济利益、信誉、应用、数据损失或其他无形损失，唱享视界不承担任何直接、间接、连带、特别、衍生性或惩罚性赔偿责任：
        1）本服务之使用或无法使用；
        2）为替换从或通过本服务购买或取得之任何商品、数据、信息、服务，收到的讯息，或缔结之交易而发生的成本；
        3）您的传输或数据遭到未获授权的存取或变造；
        4）任何第三方在本服务中所作之声明或行为；
        5）与本服务相关的其他事宜，但本使用协议有明确规定的除外；
        6）第三方以任何方式发布或投递欺诈性信息，或诱导用户受到经济损失，唱享视界不承担任何责任。
        
        21. 唱享视界商标信息
        唱享视界网站、唱享视界软件以及其他唱享视界注册商标、标志及产品、服务名称，均为星能文化公司之授权使用商标（以下简称“唱享视界标记”）。未经唱享视界事先书面同意，您同意不将唱享视界标记以任何方式展示或使用或作其他处理，或表示您有权展示、使用或另行处理唱享视界标记。
        
        22. 唱享视界之专属权利
        唱享视界尊重他人知识产权，呼吁用户也要同样尊重知识产权。唱享视界之服务与资料是基于“现状”提供，而且唱享视界明确地表示拒绝对于“服务”、“资料”或“产品”给予任何明示或暗示之保证，包括但不限于，得为商业使用或适合于特定目的之保证。唱享视界对于因“服务”、“资料”或“产品”所生之任何直接、间接、附带的或因此而导致之衍生性损失概不负责。如果您对他人的知识产权造成了侵害，唱享视界将依国家法律法规的规定，或在适当的情形下，将依其服务条款或其相关规范性规定，删除特定内容或以至终止您对账户的使用并有权删除相关内容。
        唱享视界尊重他人的任何权利（包括知识产权），同时也要求我们的使用者也尊重他人之权利。唱享视界在适当情况下，得自行决定终止侵害或违反他人权利之使用者的帐号并有权删除相关内容。若您认为您的作品的着作权遭到侵害或您的知识产权被侵犯，根据《信息网络传播权保护条例》的规定，您需及时向唱享视界联系并提供详实的举证材料。或请到中华人民共和国国家版权局下载《要求删除或断开链接侵权网络内容的通知》（下称“删除通知”）的示范格式，如果您不明白“删除通知”的内容，请登录中华人民共和国国家版权局查看《要求删除或断开链接侵权网络内容的通知》填写说明。
        
        23. 一般条款
        1）本使用协议、社区指导原则、用户隐私政策和免责声明构成您与唱享视界之全部协议，并规范您对于本服务之使用行为。在您使用相关服务、使用第三方提供的内容或软件时，亦应遵从所适用之附加条款及条件；
        2）本使用协议及您与唱享视界之关系，均受到中华人民共和国法律管辖。您与唱享视界就本服务、本使用协议或其他有关事项发生的争议，应首先友好协商解决，协商不成时应提请广州仲裁委员会仲裁，仲裁地点为广州，仲裁裁决是终局性的，对双方均有约束力；
        3）唱享视界未行使或执行本使用协议任何权利或规定，不构成对前述权利或权利之放弃；
        4）倘本使用协议之任何规定因与中华人民共和国法律抵触而无效，您依然同意应依照法律，努力使该规定所反映之当事人意向具备效力，且本使用协议其他规定仍应具有完整的效力及效果；
        5）本使用协议之标题仅供方便而设，不具有任何法律或契约效果；
        6) 只要您登录了唱享视界，就代表您接受任何以上所有协议。
        7）对本使用协议有异议的由唱享视界负责解释。
        
        24. 版权声明
        唱享视界尊重他人着作权，并在唱享视界服务条款中明定网友使用唱享视界服务不得侵害他人之着作权。因此，唱享视界郑重呼吁使用者尊重他人之着作权。如果您发现唱享视界网站中之任何网页内容或网友使用唱享视界服务已侵害您的着作权，建议您利用本处理办法提出检举，唱享视界客服中心将尽快为您处理。
        若唱享视界网站中之任何内容或网友使用唱享视界服务已侵害您的着作权，请及时发送邮件到drmcn@qq.com提供所需之资料及声明，如有必要我们会联系你以传真的方式发送相关资料。唱享视界在接获您的通知后，将尽快移除您所主张涉有侵害着作权之内容。除经使用者同意或于提供服务之目的者外，唱享视界仅得依法令或政府机关之要求，提供使用者之识别资料予第三人。因之，您如依本办法提出检举，唱享视界仅会依您的请求要求内容提供方移除该侵权内容，而不会提供您有关该使用者之识别资料。您如欲取得该使用者资料，您应向着作权行政管理机构、司法机关提起权利主张，唱享视界将于前述单位来函要求提供使用者资料后即刻配合。
        """
        agreementVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(agreementVC, animated: true)
    }
    
    @objc private func handlePrivacyPolicy() {
        let agreementVC = AgreementViewController()
        agreementVC.agreementTitle = "隐私协议"
        agreementVC.contentTitleText = "用户隐私保护政策"
        agreementVC.contentText = """
        引言
        唱享视界尊重您（以下简称“用户”）的隐私。您在使用唱享视界服务（包括唱享视界网站和唱享视界移动应用平台）时，唱享视界可能会收集和使用您的信息。唱享视界希望通过本《用户隐私政策》（以下简称为“《隐私政策》”）向您说明在您使用唱享视界的服务时，唱享视界如何收集、使用、储存和分享这些信息，以及唱享视界为您提供的访问、更新、控制和保护这些信息的方式。本《隐私政策》与您所使用的唱享视界服务息息相关，唱享视界也希望您能够仔细阅读，并在需要时，按照本《隐私政策》的指引，作出您认为适当的选择。本《隐私政策》之中涉及的相关技术词汇，唱享视界尽量以简明扼要的表述向您解释，并提供了进一步说明的链接，以便您的理解。如您对本《隐私政策》或与本《隐私政策》相关的事宜有任何问题，请通过drmcn@qq.com与唱享视界联系。更新日期：2025年8月15日生效日期：2025年8月15日
        
        1. 唱享视界收集的信息
        唱享视界提供服务时，可能会收集、储存和使用下列与您有关的信息。如果您不提供相关信息，可能无法注册成为唱享视界的用户、享受唱享视界提供的某些服务，或者即便唱享视界可以继续向您提供一些服务，也无法达到该服务拟达到的效果。
        
        2. 您提供的信息
        您在注册唱享视界的账户或使用唱享视界的服务时，向唱享视界提供的相关个人信息，例如电话号码、电子邮件等；您通过唱享视界的服务向其他方提供的共享信息，以及您使用唱享视界的服务时所储存的信息。
        
        3. 其他方分享的您的信息
        其他方使用我们的服务时所提供有关您的共享信息。
        
        4. 唱享视界获取的您的信息
        您使用唱享视界服务时唱享视界可能收集如下信息：
        日志信息指您使用唱享视界服务时，系统可能会通过cookies、web beacon或其他方式自动采集的技术信息，包括：设备或软件信息，例如您的硬件设备、网页浏览器或您用于接入唱享视界的服务的其他程序所提供的配置信息、您的IP地址和您的硬件设备所用的版本和设备识别码、序列号；您在使用唱享视界服务时搜索和浏览的信息，例如您使用的网页搜索词语、访问的社交媒体页面url地址，以及您在使用唱享视界服务时浏览或要求提供的其他信息和内容详情；有关您曾使用的移动应用（APP）和其他软件的信息，以及您曾经使用该等移动应用和软件的信息；您通过唱享视界的服务进行通讯的信息，例如曾通讯的账号，以及通讯时间、数据和时长；您通过唱享视界的服务分享的内容所包含的信息（元数据），例如拍摄或上传的共享照片或录像的日期、时间或地点等。
        位置信息指您开启设备定位功能并使用唱享视界基于位置提供的相关服务时，唱享视界收集的有关您位置的信息，包括：您通过具有定位功能的硬件设备使用唱享视界的服务时，唱享视界通过GPS或WiFi等方式收集的您的地理位置信息；您或其他用户提供的包含您所处地理位置的实时信息，例如您提供的账户信息中包含的您所在地区信息，您或其他人上传的显示您当前或曾经所处地理位置的共享信息，例如您或其他人共享的照片包含的地理标记信息；您可以通过关闭定位功能随时停止唱享视界对您的地理位置信息的收集。
        
        5. 唱享视界如何使用您的信息
        唱享视界可能将在向您提供服务的过程之中所收集的信息用作下列用途：向您提供服务；在唱享视界提供服务时，用于身份验证、客户服务、安全防范、诈骗监测、存档和备份用途，确保唱享视界向您提供的产品和服务的安全性；帮助唱享视界设计新服务，改善唱享视界现有服务；使唱享视界更加了解您如何接入和使用唱享视界的服务，从而针对性地回应您的个性化需求，例如语言设定、位置设定、个性化的帮助服务和指示，或对您和其他使用唱享视界服务的用户作出其他方面的回应；向您提供与您更加相关的广告以替代普遍投放的广告；评估唱享视界服务中的广告和其他促销及推广活动的效果，并加以改善；软件认证或管理软件升级；让您参与有关唱享视界产品和服务的调查。
        为了让唱享视界的用户有更好的体验、改善唱享视界的服务或您同意的其他用途，在符合相关法律法规的前提下，唱享视界可能将通过唱享视界的某一项服务所收集的个人信息，以汇集信息或者个性化的方式，用于唱享视界的其他服务。例如，在您使用唱享视界的一项服务时所收集的您的个人信息，可能在另一服务中用于向您提供特定内容或向您展示与您相关的、而非普遍推送的信息。如唱享视界在相关服务之中提供了相应选项，您也可以主动要求唱享视界将您在该服务所提供和储存的个人信息用于唱享视界的其他服务。针对某些特定服务的特定隐私政策将更具体地说明唱享视界在该等服务中如何使用您的信息。
        
        6. 如何访问和控制您的信息
        唱享视界将尽量采取适当的技术手段，保证您可以访问、更新和更正您的注册信息或使用唱享视界的服务时提供的其他个人信息。在访问、更新、更正和删除您的个人信息时，唱享视界可能会要求您进行身份验证，以保障您的账户安全。
        
        7. 唱享视界如何分享您的信息
        除以下情形外，未经您同意，唱享视界、唱享视界关联方或合作方不会与任何第三方分享您的个人信息：
        唱享视界以及唱享视界的关联公司可能将您的个人信息与唱享视界的关联公司、合作方及第三方服务供应商、服务商及代理（例如代表唱享视界发出电子邮件或推送通知的通讯服务提供商、以及为唱享视界提供位置数据的地图服务供应商）分享，用作下列用途：向您提供唱享视界的服务；实现“唱享视界如何使用您的信息”部分所述目的；履行唱享视界在本《隐私政策》中的义务和行使唱享视界的权利；理解、维护和改善唱享视界的服务。
        如唱享视界或唱享视界的关联公司与任何上述第三方分享您的个人信息，唱享视界将努力确保该等第三方在使用您的个人信息时遵守本《隐私政策》及唱享视界要求其遵守的其他适当的保密和安全措施。
        随着唱享视界业务的持续发展，唱享视界以及唱享视界所有或授权的关联公司有可能进行合并、收购、资产转让或类似的交易，而您的个人信息有可能作为此类交易的一部分而被转移。唱享视界将在您的个人信息转移前通知您。唱享视界或唱享视界的关联公司还可能为以下需要保留、保存或披露您的个人信息：遵守适用的法律法规；遵守法院命令或其他法律程序的规定；遵守相关政府机关的要求；唱享视界为遵守适用的法律法规、维护社会公共利益、或保护唱享视界或唱享视界的所有或授权公司、唱享视界的客户、其他用户或雇员的人身和财产安全或合法权益所合理必需的。
        
        8. 唱享视界如何保留、储存和保护您的信息
        唱享视界仅在本《隐私政策》所述目的所必需期间和法律法规要求的时限内保留您的个人信息。唱享视界使用各种安全技术和程序，以防信息的丢失、不当使用、未经授权阅览或披露。但请您谅解，由于技术的限制以及风险防范的局限，即便唱享视界已经尽量加强安全措施，也无法始终保证信息百分之百的安全。您需要了解，您接入唱享视界的服务所用的系统和通讯网络，有可能因唱享视界可控范围外的情况而发生问题。
        
        9. 有关共享信息的提示
        唱享视界的多项服务可让您不仅与您的社交网络、也与使用该服务的所有用户公开分享您的相关信息，例如，您在唱享视界的服务中所上传或发布的信息（包括您公开的个人信息、您建立的名单）、您对其他人上传或发布的信息作出的回应，以及包括与这些信息有关的位置数据和日志信息。使用唱享视界服务的其他用户也有可能分享与您有关的信息（包括位置数据和日志信息）。特别是唱享视界的社交媒体服务，是专为使您可以与各地的用户共享信息而设计，从而使共享信息可实时、广泛地传递。只要您不删除共享信息，有关信息便一直留存在公众领域；即使您删除共享信息，有关信息仍可能由其他用户或不受唱享视界控制的非关联第三方独立地缓存、复制或储存，或由其他用户或该等第三方在公众领域保存。因此，请您认真考虑您通过唱享视界的服务上传、发布和交流的信息内容。在一些情况下，您可通过唱享视界某些服务的隐私设定来控制有权浏览您的共享信息的用户范围。如您要求从唱享视界的服务中删除您的个人信息，请通过该等特别服务条款提供的方式操作。
        
        10. 有关敏感个人信息的提示
        某些个人信息因其特殊性可能被认为是敏感个人信息，例如您的种族、宗教、个人健康和医疗信息等。相比其他个人信息，敏感个人信息受到更加严格的保护。请注意，您在我们的服务中所提供、上传或发布的内容和信息（例如有关您社交活动的照片或信息），可能会泄露您的敏感个人信息。您需要谨慎地考虑，是否使用我们的服务披露您的敏感个人信息。您同意您的敏感个人信息按本《隐私政策》所述的目的和方式来处理。
        
        11. COOKIES、日志档案和WEB BEACON
        唱享视界和第三方合作伙伴可能通过cookies和web beacon收集和使用您的信息，并将该等信息储存为日志信息。唱享视界使用自己的cookies和web beacon，目的是为您提供更个性化的用户体验和服务，并用于以下用途：记住您的身份。例如：cookies和web beacon有助于唱享视界辨认您作为唱享视界的注册用户的身份，或保存您向唱享视界提供有关您的喜好或其他信息；分析您使用唱享视界服务的情况。唱享视界可利用cookies和web beacon来了解您使用唱享视界的服务进行什幺活动、或哪些网页或服务最受欢迎；广告优化。Cookies和web beacon有助于唱享视界根据您的信息，向您提供与您相关的广告而非进行普遍的广告投放。唱享视界为上述目的使用cookies和web beacon的同时，可能将通过cookies和web beacon收集的非个人身份信息汇总提供给广告商和其他伙伴，用于分析您和其他用户如何使用唱享视界的服务并用于广告服务。唱享视界的产品和服务上可能会有广告商和其他合作方放置的cookies和web beacon。这些cookies和web beacon可能会收集与您相关的非个人身份信息，以用于分析用户如何使用该等服务、向您发送您可能感兴趣的广告，或用于评估广告服务的效果。这些第三方cookies和web beacon收集和使用该等信息不受本《隐私政策》约束，而是受到其自身的隐私政策约束，唱享视界不对第三方的cookies或web beacon承担责任。您可以通过浏览器设置拒绝或管理cookies或web beacon。但请您注意，如果您停用cookies或web beacon，唱享视界有可能无法为您提供最佳的服务体验，某些服务也可能无法正常使用。同时，您仍然将收到同样数量的广告，只是这些广告与您的相关性会降低。
        
        12. 广告
        唱享视界可能使用您的信息，向您提供与您更加相关的广告。唱享视界也可能使用您的信息，通过唱享视界的服务、电子邮件或其他方式向您发送营销信息，提供或推广唱享视界或第三方的如下商品和服务：唱享视界的商品和服务，以及唱享视界的关联公司和合营伙伴的商品和服务，包括即时通讯服务、网上媒体服务、互动娱乐服务、社交网络服务、付款服务、互联网搜索服务、位置和地图服务、应用软件和服务、数据管理软件和服务、网上广告服务及其他社交媒体、娱乐、电子商务、资讯及通讯软件和服务（“互联网服务”）；第三方互联网服务供应商，以及与下列有关的第三方商品和服务：食物和餐饮、体育、音乐、电影、电视、现场表演和其他艺术和娱乐、书册、杂志和其他刊物、服装和配饰、珠宝、化妆品、个人健康和卫生、电子、收藏品、家用器皿、电器、家居装饰和摆设、宠物、汽车、酒店、交通和旅游、银行、保险及金融服务、会员积分和奖励计划，以及唱享视界认为可能与您相关的其他商品和服务。如您不希望唱享视界将您的个人信息用作前述广告用途，您可以通过唱享视界在广告中提供的相关指示、或在特定服务中提供的指引，要求唱享视界停止为上述用途使用您的个人信息。
        
        13. 唱享视界向您发送的邮件和信息邮件和信息推送
        您使用唱享视界服务时，唱享视界可能使用您的信息向您的设备发送电子邮件、新闻或推送通知。如您不希望收到这些信息，您可以按照唱享视界向您发出的电子邮件所述指示，在设备上选择取消订阅。唱享视界可能在必需时（例如当唱享视界由于系统维护而暂停某一项服务时）向您发出与服务有关的公告。您可能无法取消这些与服务有关、性质不属于推广的公告。
        
        14. 我们服务中的第三方服务
        我们的服务可能包括或链接至第三方提供的社交媒体或其他服务（包括网站）。例如：您可利用“分享”键将某些内容分享到我们的服务，或您可利用第三方连线服务登录我们的服务。这些功能可能会收集您的信息（包括您的日志信息），并可能在您的硬件装置cookies，从而正常运行上述功能；我们通过广告或我们服务的其他方式向您提供链接，使您可以接入第三方的服务或网站。该等第三方社交媒体或其他服务可能由相关的第三方或我们运营。您使用该等第三方的社交媒体服务或其他服务（包括您向该等第三方提供的任何个人信息），须受第三方自己的服务条款及隐私政策约束，您需要仔细阅读其条款。本《隐私政策》仅适用于我们所收集的任何信息，并不适用于任何第三方提供的服务或第三方的信息使用规则，而我们对任何第三方使用由您提供的信息不承担任何责任。
        
        唱享视界硬件版接入了以下第三方APP及SDK：
        APP名称：5G宽视界、唱吧
        SDK名称：友盟SDK
        服务类型：应用统计分析
        收集个人信息类型：设备信息（IMEI/MAC/Android ID/IDFA/OpenUDID/GUID/IP地址/SIM 卡 IMSI 信息等）
        隐私权政策链接：https://www.umeng.com/page/policy
        
        SDK名称：Talkingata应用统计SDK
        服务类型：应用统计分析；作弊防护
        收集个人信息类型：设备信息（设备品牌、型号、软件版本等基础信息）、网络信息（设备连接wifi和基站信息）、位置信息、应用信息
        隐私权政策链接：https://www.talkingdata.com/privacy.jsp?languagetype=zh_cn
        
        SDK名称：微信openSDK
        服务类型：微信账号登录
        收集个人信息类型：用户选择的微信头像、昵称
        隐私权政策链接：https://support.weixin.qq.com/cgi-bin/mmsupportacctnodeweb-bin/pages/ONwPihxKd82RAkIJ
        
        SDK名称：七牛云
        服务类型：上传录制的作品
        收集个人信息类型：IP地址、当前网络类型、WIFI信息、MAC地址、IMEI、Android ID
        隐私权政策链接：https://www.qiniu.com/agreements/privacy-right
        
        15. 年龄限制
        唱享视界鼓励父母或监护人指导未满十八岁的未成年人使用唱享视界的服务。唱享视界建议未成年人鼓励他们的父母或监护人阅读本《隐私政策》，并建议未成年人在提交的个人信息之前寻求父母或监护人的同意和指导。未成年人在唱享视界的行为均视为已经获得其父母或监护人的同意和指导。
        
        16. 本《隐私政策》的适用范围
        除某些特定服务外，唱享视界所有的服务均适用本《隐私政策》。这些特定服务将适用特定的隐私政策。该特定服务的隐私政策构成本《隐私政策》的一部分。如任何特定服务的隐私政策与本《隐私政策》有不一致之处，则适用特定服务的隐私政策。请您注意，本《隐私政策》不适用于以下情况：通过唱享视界的服务而接入的第三方服务（包括任何第三方网站）收集的信息；通过在唱享视界服务中提供广告服务的第三方所收集的信息。
        
        17. 本《隐私政策》的修改
        唱享视界可能随时修改本《隐私政策》的条款，该等修改构成本《隐私政策》的一部分。如该等修改造成您在本《隐私政策》下权利的实质减少，唱享视界将在修改生效前通过在主页上显着位置提示或向您发送电子邮件或以其他方式通知您，在该种情况下，若您继续使用唱享视界的服务，即表示同意受经修订的本《隐私政策》的约束。
        """
        agreementVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(agreementVC, animated: true)
    }
    
    @objc private func handleLogout() {
        showConfirmDialog(title: "退出账号", message: "确定退出？", confirmTitle: "确定") {
            self.executeLogout()
        }
    }
    
    @objc private func handleDeleteAccount() {
        showConfirmDialog(title: "注销账号", message: "确定注销账号？", confirmTitle: "确定注销") {
            print("执行逻辑删除此用户...")
            self.executeLogout()
        }
    }
    
    private func executeLogout() {
        // 清空 Token 和状态
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
        // 切换根视图到登录页
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let loginNav = UINavigationController(rootViewController: LoginViewController())
            loginNav.isNavigationBarHidden = true
            window.rootViewController = loginNav
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    // 自定义弹窗
    private func showConfirmDialog(title: String, message: String, confirmTitle: String, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            onConfirm()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true, completion: nil)
    }
}