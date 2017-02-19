import Foundation


protocol RelatedPostsViewControllerDelegate: class {
    func loadedRelatedPosts()
}


class RelatedPostsViewController: UIViewController {

    @IBOutlet var relatedSitestackView: UIStackView!
    @IBOutlet var relatedWPComStackView: UIStackView!
    @IBOutlet var siteLabel: UILabel!
    @IBOutlet var wpcomLabel: UILabel!

    var delegate: RelatedPostsViewControllerDelegate?

    var post: ReaderPost? {
        didSet {
            setupSiteLable()
            fetchRelatedPostsIfNeeded()
        }
    }


    open class func controllerWithPost(_ post: ReaderPost) -> RelatedPostsViewController {
        let controller = RelatedPostsViewController()
        controller.post = post
        return controller
    }


    // Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLongPressGestureRecognizer()
        setupWPComLabel()
        configureView()
    }


    // Configuration

    /// NOTE: Because of how the RelatedPostsViewController's view is composed in
    /// the ReaderDetailViewController, a longpress on the view or its subviews
    /// could trigger text selection in the WPRichContentView. To avoid this, we add
    /// a UILongPressGestureRecognizer to catch the gestures and prevent triggering
    /// text selection.
    /// This could be rendered unnecessary by future changes to the
    /// ReaderDetailViewController.
    func setupLongPressGestureRecognizer() {
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(self.handleCardLongPress))
        lpgr.cancelsTouchesInView = true
        view.addGestureRecognizer(lpgr)
    }


    func setupSiteLable() {
        if let post = post {
            let siteTitle = post.blogName.uppercased()
            siteLabel.text = NSLocalizedString("MORE IN \(siteTitle)", comment: "Capitalized title. The text '\(siteTitle)' is a placeholder for the title of the user's site.").uppercased()
        }
    }


    func setupWPComLabel() {
        wpcomLabel.text = NSLocalizedString("MORE ON WORDPRESS.COM", comment: "Capitalized title.").uppercased()
    }


    func configureView() {
        configureSitePosts()
        configureWPComPosts()

        delegate?.loadedRelatedPosts()
    }


    // Content

    func configureSitePosts() {
        let posts = filteredSitePosts()

        relatedSitestackView.isHidden = posts.count == 0

        for post in posts {
            let card = cardForRelatedPost(relatedPost: post)
            relatedSitestackView.addArrangedSubview(card)
        }
    }


    func filteredSitePosts()-> [ReaderPost] {
        guard let post = post else {
            return [ReaderPost]()
        }

        let posts = post.relatedPosts.filter { (relatedPost) -> Bool in
            return relatedPost.siteID.intValue == post.siteID.intValue
        }

        return posts
    }


    func configureWPComPosts() {
        let posts = filteredWPComPosts()

        relatedWPComStackView.isHidden = posts.count == 0

        for post in posts {
            let card = cardForRelatedPost(relatedPost: post)
            relatedWPComStackView.addArrangedSubview(card)
        }
    }


    func filteredWPComPosts() -> [ReaderPost] {
        guard let post = post else {
            return [ReaderPost]()
        }

        let posts = post.relatedPosts.filter { (relatedPost) -> Bool in
            return relatedPost.siteID.intValue != post.siteID.intValue
        }

        return posts
    }


    func cardForRelatedPost(relatedPost: ReaderPost) -> ReaderCard {
        // Arbitrary starting frame
        let frame = CGRect(x: 0, y: 0, width: 320, height: 100)

        let card = ReaderCard(frame: frame)
        card.delegate = self
        card.hidesActionbar = true
        card.headerButtonIsEnabled = false
        card.cardContentMargins = .zero
        card.hidesFollowButton = relatedPost.siteID.intValue == post?.siteID.intValue

        card.readerPost = relatedPost

        let tgr = UITapGestureRecognizer(target: self, action: #selector(self.handleCardTapped))
        card.addGestureRecognizer(tgr)

        return card
    }


    // Actions

    func handleCardTapped() {
        // TODO:
    }


    /// No op
    func handleCardLongPress() {}


    // Fetching

    func fetchRelatedPostsIfNeeded() {
        guard let post = post else {
            return
        }

        if post.relatedPosts.count > 0 {
            configureView()
            return
        }

        let context = ContextManager.sharedInstance().newDerivedContext()
        let service = ReaderPostService(managedObjectContext: context)
        service.fetchRelatedPosts(for: post, success: { [weak self] in
            self?.configureView()
        }, failure: { (error) in
            // Fail silently.
            DDLogSwift.logInfo("\(error)")
        })

    }

}


extension RelatedPostsViewController: ReaderCardDelegate {

    func readerCard(_ card: ReaderCard, followActionForPost post: ReaderPost) {
        ReaderHelpers.toggleFollowingForPost(post)
        // Reassigning the post updates the card and the status of the follow button
        card.readerPost = post
    }

    func readerCardImageRequestAuthToken() -> String? {
        return nil
    }

    // No ops

    func readerCard(_ card: ReaderCard, headerActionForPost post: ReaderPost) {}

    func readerCard(_ card: ReaderCard, commentActionForPost post: ReaderPost) {}

    func readerCard(_ card: ReaderCard, shareActionForPost post: ReaderPost, fromView sender: UIView) {}

    func readerCard(_ card: ReaderCard, visitActionForPost post: ReaderPost) {}

    func readerCard(_ card: ReaderCard, likeActionForPost post: ReaderPost) {}

    func readerCard(_ card: ReaderCard, menuActionForPost post: ReaderPost, fromView sender: UIView) {}

    func readerCard(_ card: ReaderCard, attributionActionForPost post: ReaderPost) {}

}