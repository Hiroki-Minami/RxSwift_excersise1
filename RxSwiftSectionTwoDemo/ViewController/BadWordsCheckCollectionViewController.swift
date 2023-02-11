//
//  BadWordsCheckCollectionViewController.swift
//  RxSwiftSectionTwoDemo
//
//  Created by Hiroki Minami on 2023-02-10.
//

import UIKit
import RxRelay
import RxSwift

class BadWordsCheckCollectionViewController: UIViewController {
  
  var badPosts: [Post] = []
  
  @IBOutlet var collectionView: UICollectionView!
  
  var dataSource: UICollectionViewDiffableDataSource<Section, Post>!
  var itemSnapshot: NSDiffableDataSourceSnapshot<Section, Post> {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Post>()
    
    snapshot.appendSections([.main])
    snapshot.appendItems(badPosts)
    
    return snapshot
  }
  
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView.setCollectionViewLayout(generateComplicatedLayout(), animated: false)
    createDataSource()
    setObservable()
  }
  
  private func setObservable() {
    let liveViewController = tabBarController?.viewControllers?.first as! ViewController
    let postObservable = liveViewController.postObservable.share()
    
    postObservable
      .filter { post in
        !Util.checkBadWords(post) || !post.poster.validation()
      }
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        self?.badPosts.append($0)
        self?.dataSource.apply(self!.itemSnapshot, animatingDifferences: true) {
          self?.collectionView.scrollToItem(at: IndexPath(item: self!.badPosts.count - 1, section: 0), at: .bottom, animated: true)
        }
        Poster.badWordsCount[$0.poster] = (Poster.badWordsCount[$0.poster] != nil) ? Poster.badWordsCount[$0.poster]! + 1: 1
      })
      .disposed(by: disposeBag)
  }
  
  fileprivate func createDataSource() {
    dataSource = UICollectionViewDiffableDataSource<Section, Post>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier -> UICollectionViewCell? in
      
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadComments", for: indexPath) as! PostCollectionViewCell
      
      cell.commentLabel.text = itemIdentifier.text
      cell.posterLabel.text = itemIdentifier.poster.name
      
      return cell
    })
    
    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
      let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "BadCommentsHeader", for: indexPath) as!
      PostHeaderCollectionReusableView
      return header
    }
    let liveViewController = tabBarController?.viewControllers?.first as! ViewController
    badPosts.append(contentsOf: liveViewController.badPosts)
    
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
  enum Section {
    case main
  }
}
