//
//  ViewController.swift
//  RxSwiftSectionTwoDemo
//
//  Created by Hiroki Minami on 2023-02-09.
//

import UIKit
import RxSwift

class ViewController: UIViewController {
  
  @IBOutlet var liveImageView: UIImageView!
  @IBOutlet var commentTextField: UITextField!
  
  @IBOutlet var collectionView: UICollectionView!
  // subject posts
  private var filteredPosts: [Post] = []
  var badPosts: [Post] = []
  
  private var dataSource: UICollectionViewDiffableDataSource<Section, Post>!
  private var itemSnapshot: NSDiffableDataSourceSnapshot<Section, Post> {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Post>()
    
    snapshot.appendSections([.main])
    snapshot.appendItems(filteredPosts)
    
    return snapshot
  }
  
  var postObservable: Observable<Post> {
    return postSubject.asObserver()
  }
  
  private var temporaryDisposable: Disposable?
  private let postSubject = PublishSubject<Post>()
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView.setCollectionViewLayout(generateComplicatedLayout(), animated: false)
    createDataSource()
    postingOthersBackground()
    
    setObservable()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.temporaryDisposable?.dispose()
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    guard let comment = commentTextField.text else { return }
    let post = Post(text: comment, poster: Poster.loginUser)
    
    postSubject.onNext(post)
  }
  
  fileprivate func setObservable() {

    postSubject
      .filter { post in
        return Util.checkBadWords(post) && post.poster.validation()
      }
      .distinctUntilChanged()
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        self?.filteredPosts.append($0)
        DispatchQueue.main.async {
          self?.dataSource.apply(self!.itemSnapshot, animatingDifferences: true, completion: {
            self?.collectionView.scrollToItem(at: IndexPath(item: (self?.filteredPosts.count)! - 1, section: 0), at: .bottom, animated: true)
          })
        }
      })
      .disposed(by: disposeBag)
    
    // sharing observable
    let temporaryPostObservable = postSubject.share()
    temporaryDisposable =
    temporaryPostObservable
      .filter { post in
        return !Util.checkBadWords(post) || !post.poster.validation()
      }
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        self?.badPosts.append($0)
        Poster.badWordsCount[$0.poster] = (Poster.badWordsCount[$0.poster] != nil) ? Poster.badWordsCount[$0.poster]! + 1: 1
      })
  }
  
  private func postingOthersBackground() {
    Task {
      let posters = Poster.makeFiveRandomPosters()
      var number = 1
      while true {
        for poster in posters {
          var post: Post
          if poster.name == "user3" && Bool.random() {
            post = Post(text: "bad post \(number)", poster: poster)
          } else {
            post = Post(text: "post \(number)", poster: poster)
          }
          postSubject.onNext(post)
          try await Task.sleep(nanoseconds: 2_000_000_000)
          number += 1
        }
      }
    }
  }
  
  fileprivate func createDataSource() {
    dataSource = UICollectionViewDiffableDataSource<Section, Post>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier -> UICollectionViewCell? in
      
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Comments", for: indexPath) as! PostCollectionViewCell
      
      cell.commentLabel.text = itemIdentifier.text
      cell.posterLabel.text = itemIdentifier.poster.name
      
      return cell
    })
    
    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
      let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! PostHeaderCollectionReusableView
      return header
    }
    
    dataSource.apply(itemSnapshot)
  }
  
  fileprivate func generateComplicatedLayout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
    group.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    
    let section = NSCollectionLayoutSection(group: group)
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
    
    let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    section.boundarySupplementaryItems = [sectionHeader]
    
    return UICollectionViewCompositionalLayout(section: section)
  }
  
  enum Section: CaseIterable {
    case main
  }
}

