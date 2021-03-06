//
//  QQDetailVC.swift
//  QQMusic
//
//  Created by 迪拜葱油王子 on 2016/11/4.
//  Copyright © 2016年 迪拜葱油王子. All rights reserved.
//

import UIKit

// MARK:- 存放属性
class QQDetailVC: UIViewController {

    @IBOutlet weak var lrcScrollView: UIScrollView!
    
    // 歌词的视图
    lazy var lrcVc: QQLrcTVC? = {
    
        return QQLrcTVC()
    }()

    
    // 分析界面，根据不同的更新频率，采用不同的方案赋值
    /** 歌词动画背景 1 */
    @IBOutlet weak var foreImageView: UIImageView!
    /** 背景图片 1 */
    @IBOutlet weak var backImageView: UIImageView!
    /** 歌曲名称 1 */
    @IBOutlet weak var songNameLabel: UILabel!
    /** 歌手名称 1 */
    @IBOutlet weak var singNameLabel: UILabel!
    /** 总时长 1 */
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    /** 歌词label n */
    @IBOutlet weak var lrclabel: QQLrcLabel!
    /** 已经播放时长 n */
    @IBOutlet weak var costTimeLabel: UILabel!
    /** 进度条 n */
    @IBOutlet weak var progressSlider: UISlider!
    
    @IBOutlet weak var playOrPauseBtn: UIButton!
    
    // 负责更新很多次的timer
    var timer: Timer?
    
    // 负责更新歌词的Link
    var updateLrcLink : CADisplayLink?
}

// MARK:- 业务逻辑
extension QQDetailVC {
    
    @IBAction func close() {
        navigationController?.popViewController(animated: true)
    }
    
    // 播放或者暂停
    @IBAction func playOrPause(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            QQMusicOperationTool.shareInstance.playCurrentMusic()
            resumeRotationAnimation()
            
        }else
        {
            QQMusicOperationTool.shareInstance.pauseCurrentMusic()
            pauseRotationAnimation()
        }
    }
    @IBAction func preMusic() {
        QQMusicOperationTool.shareInstance.preMusic()
        
        // 切换一次更新界面的操作
        setupOnce()
    }
    @IBAction func nextMusic() {
        QQMusicOperationTool.shareInstance.nextMusic()
        
        setupOnce()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupOnce()
        
        addTimer()
        
        addLink()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removerTimer()
        
        removeLink()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addLrcView()
        setupLrcScrollView()
        setSlider()
    }
    
    
    // 当歌曲切换时，需要更新一次的操作
    func setupOnce() -> (){
        
        let musicMessageM = QQMusicOperationTool.shareInstance.getMusicMessageModel()

        guard let musicM = musicMessageM.musicM else {return}
        
        /** 背景图片 1 */
        if musicM.icon != nil{
            backImageView.image = UIImage(named: (musicM.icon)!)
            // 前进图片
            foreImageView.image = UIImage(named: (musicM.icon)!)
        }
        /** 歌曲名称 1 */
        songNameLabel.text = musicM.name
        /** 歌手名称 1 */
        singNameLabel.text = musicM.singer
        /** 总时长 1 */
        totalTimeLabel.text = QQTimeTool.getFormatTime(timeInterval: musicMessageM.totalTime)
        
        // 切换最新的歌词
        let lrcMs = QQMusicDataTool.getLrcMs(lrcName: musicM.lrcname)
        lrcVc?.lrcMs = lrcMs
        
        addRotationAnimation()
        
        if musicMessageM.isPlaying{
            resumeRotationAnimation()
        }else{
            pauseRotationAnimation()
        }
    }
    
    
    // 当歌曲切换时，需要更新N次的操作
    func setupTimes() -> (){
        
        let musicMessageM = QQMusicOperationTool.shareInstance.getMusicMessageModel()

        /** 歌词label n */
//        lrclabel.text = ""
        
        /** 已经播放时长 n */
        costTimeLabel.text = QQTimeTool.getFormatTime(timeInterval: musicMessageM.costTime)
        /** 进度条 n */
        progressSlider.value = Float(musicMessageM.costTime / musicMessageM.totalTime)
    
        playOrPauseBtn.isSelected = musicMessageM.isPlaying
    }
    
    
    func addTimer() -> (){
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(QQDetailVC.setupTimes), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
    }
    
    func removerTimer() -> (){
        timer?.invalidate()
        timer = nil
    }
    
    func addLink() -> (){
        updateLrcLink =  CADisplayLink(target: self, selector: #selector(QQDetailVC.updateLrc))
        updateLrcLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    func removeLink() -> (){
        updateLrcLink?.invalidate()
        updateLrcLink = nil
    }
    
    // 更新歌词
    func updateLrc() -> (){
        let musicMessageM = QQMusicOperationTool.shareInstance.getMusicMessageModel()
        
        // 拿到歌词
        // 当前时间
        let time = musicMessageM.costTime
        
        // 歌词数组
        let lrcMs = lrcVc?.lrcMs
        
        let rowLrcM = QQMusicDataTool.getCurrentLrcM(currentTime: time, lrcMs: lrcMs!)
        
        let lrcM = rowLrcM.lrcM
        
        // 赋值
        lrclabel.text = lrcM?.lrcContent
        
        // 进度
        if(lrcM != nil){
            let time1 = time - lrcM!.beginTime
            let time2 = lrcM!.endTime - lrcM!.beginTime
            
            lrclabel.radio = CGFloat(time1 / time2)
        }
        lrcVc?.progress = lrclabel.radio
        
        
        // 滚动歌词
        // 滚到哪一行
        let row = rowLrcM.row
        
        // 赋值给lrcVC，让它来负责具体怎么滚
        lrcVc?.scrollRow = row
        
        QQMusicOperationTool.shareInstance.setupLockMessage()
    }
    
}

// MARK:- 界面操作
extension QQDetailVC {

    // 添加歌词视图
    func addLrcView() -> (){
        lrcVc?.tableView.backgroundColor = UIColor.clear
        lrcScrollView.addSubview((lrcVc?.tableView)!)
    }
    
    // 调整frame
    func setLrcViewFrame() -> (){
        lrcVc?.tableView.frame = lrcScrollView.bounds
        lrcVc?.tableView.frame.origin.x = lrcScrollView.frame.size.width
        lrcScrollView.contentSize = CGSize(width: lrcScrollView.frame.size.width * 2, height: 0)
    }
    
    func setSlider() -> (){
        progressSlider.setThumbImage(UIImage(named:"player_slider_playback_thumb"), for: .normal)
    }
    
    func setupForeImageView() -> (){
        foreImageView.layer.cornerRadius = foreImageView.frame.size.width / 2
        foreImageView.layer.masksToBounds = true
    }
    
    func setupLrcScrollView() -> (){
        lrcScrollView.delegate = self
        lrcScrollView.isPagingEnabled = true
        lrcScrollView.showsHorizontalScrollIndicator = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        setLrcViewFrame()
        setupForeImageView()
    }
}


// MARK:- 做动画
extension QQDetailVC: UIScrollViewDelegate{
   
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
//        print(x)
        
        let radio = 1 - x / scrollView.frame.size.width
        
        foreImageView.alpha = radio
        lrclabel.alpha = radio
    }
    
    
    // 添加旋转动画
    func addRotationAnimation() -> (){
        
        foreImageView.layer.removeAnimation(forKey: "rotation")
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = M_PI * 2
        animation.duration = 30
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        foreImageView.layer.add(animation, forKey: "rotation")
    }
    
    // 暂停旋转动画
    func pauseRotationAnimation() -> (){
        foreImageView.layer.pauseAnimate()
    }
    
    // 继续旋转动画
    func resumeRotationAnimation() -> (){
        foreImageView.layer.resumeAnimate()
    }

}



extension QQDetailVC {

    override func remoteControlReceived(with event: UIEvent?) {
        
        let type = event?.subtype
        switch type! {
        case .remoteControlPlay:
            print("播放")
            QQMusicOperationTool.shareInstance.playCurrentMusic()
        case .remoteControlPause:
            print("暂停")
            QQMusicOperationTool.shareInstance.pauseCurrentMusic()
        case .remoteControlNextTrack:
            print("下一首")
            QQMusicOperationTool.shareInstance.nextMusic()
        case .remoteControlPreviousTrack:
            print("上一首")
            QQMusicOperationTool.shareInstance.preMusic()
        default:
            print("nono")
        }
        
        setupOnce()
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        QQMusicOperationTool.shareInstance.nextMusic()
        setupOnce()
    }
    
}







