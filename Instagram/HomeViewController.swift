//
//  HomeViewController.swift
//  Instagram
//
//  Created by 三浦　登哉 on 2020/10/16.
//  Copyright © 2020 toya.miura. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    
    @IBOutlet weak var tableView: UITableView!
    // 投稿データを格納する配列
    var postArray: [PostData] = []
    
    // Firestoreのリスナー
    var listener: ListenerRegistration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                        return
                    }
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.map { document in
                        print("DEBUG_PRINT: document取得 \(document.documentID)")
                        let postData = PostData(document: document)
                        return postData
                    }
                    print(self.postArray.count)
                    // TableViewの表示を更新する
                    self.tableView.reloadData()
                    
                }
            }
        } else {
            // ログイン未(またはログアウト済み)
            if listener != nil {
                // listener登録済みなら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                tableView.reloadData()
            }
        }
    }
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])
        // セル内のlikeボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
        // セル内のsendボタンのアクションをソースコードで設定
        cell.sendButton.addTarget(self, action:#selector(commentButton(_:forEvent:)), for:
            .touchUpInside)
        
        return cell
    }
    // セル内のlikeボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        // セルを取得
        let Cell = tableView.cellForRow(at: indexPath!) as? PostTableViewCell
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
        }        }
    
    
    @objc func commentButton(_ sender: UIButton, forEvent event: UIEvent){
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        // セルを取得
        let Cell = tableView.cellForRow(at: indexPath!) as? PostTableViewCell
        // タップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
       print("データ取り出し")
       
        // コメントを更新する
        if let commentname = Auth.auth().currentUser?.displayName,
        let comment = Cell?.commentLabel.text! {
       
        // 更新データを作成
        let updateValue1: FieldValue
        //    let updateValue2: FieldValue
        // 送信ボタンを押した場合は、commentを追加する更新データを作成
        updateValue1 = FieldValue.arrayUnion(["\(commentname) : \(comment)"])
            //updateValue2 = FieldValue.arrayUnion([comment])
        // 更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
        postRef.updateData(["comments": updateValue1])
    //    postRef.updateData(["comment": updateValue2])
        print("データ保存に成功")
        }
    }
    
    
}
