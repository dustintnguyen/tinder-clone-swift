//
//  CardView.swift
//  TinderClone
//
//  Created by David Doll on 09/05/19.
//  Copyright © 2019 David Doll. All rights reserved.
//

import UIKit
import SDWebImage

class CardView: UIView {
    
    fileprivate let barsStackView = UIStackView(frame: .zero)
    fileprivate let imageView = UIImageView(frame: .zero)
    fileprivate let gradientLayer = CAGradientLayer()
    fileprivate let informationLabel = UILabel(frame: .zero)
    fileprivate let threshold: CGFloat = 100
    fileprivate var imageCurrentIndex = 0
    fileprivate let deselectedStackBarColor = UIColor.init(white: 0, alpha: 0.1)
    
    var viewModel: CardViewModel! {
        didSet {
            if let imageUrl = URL(string: viewModel.images.first ?? "") {
                imageView.sd_setImage(with: imageUrl)
            }
            informationLabel.attributedText = viewModel.attributedString
            informationLabel.textAlignment = viewModel.textAlignment
            fillBarsStackView(count: viewModel.images.count)
            setupImageObserver()
        }
    }
    
    func setupImageObserver() {
        viewModel.imageIndexObserver = { [weak self] imageUrl, index in
            self?.imageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
            self?.barsStackView.arrangedSubviews.forEach { view in
                view.backgroundColor = self?.deselectedStackBarColor
            }
            self?.barsStackView.arrangedSubviews[index].backgroundColor = .white
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = frame
    }
    
    fileprivate func setupLayout() {
        backgroundColor = .white
        layer.cornerRadius = 10
        clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        imageView.fillSuperview()
        
        setupBarsStackView()
        
        setupGradientLayer()
        
        informationLabel.textColor = .white
        informationLabel.numberOfLines = 0
        addSubview(informationLabel)
        informationLabel.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 16, right: 16))
    }
    
    fileprivate func setupBarsStackView() {
        addSubview(barsStackView)
        barsStackView.spacing = 4
        barsStackView.distribution = .fillEqually
        barsStackView.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 8, left: 8, bottom: 0, right: 8), size: .init(width: 0, height: 4))
    }
    
    fileprivate func fillBarsStackView(count: Int) {
        (0..<count).forEach { _ in
            let barView = UIView()
            barView.clipsToBounds = true
            barView.layer.cornerRadius = 2
            barView.backgroundColor = deselectedStackBarColor
            barsStackView.addArrangedSubview(barView)
        }
        barsStackView.arrangedSubviews.first?.backgroundColor = .white
    }
    
    fileprivate func setupGradientLayer() {
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [0.5, 1.2]
        layer.addSublayer(gradientLayer)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: nil).x
        let shouldDisplayNext = location > frame.width / 2
        
        if shouldDisplayNext {
            viewModel.advanceToNextPhoto()
        } else {
            viewModel.goToPreviousPhoto()
        }
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            superview?.subviews.forEach { $0.layer.removeAllAnimations() }
        case .changed:
            handleChanged(gesture)
        case .ended:
            handleEnded(gesture)
        default:
            ()
        }
    }
    
    fileprivate func handleChanged(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: nil)
        let degrees = translation.x / 20
        let angle = degrees * .pi / 180
        
        let rotationalTransformation = CGAffineTransform(rotationAngle: angle)
        transform = rotationalTransformation.translatedBy(x: translation.x, y: translation.y)
    }
    
    fileprivate func handleEnded(_ gesture: UIPanGestureRecognizer) {
        
        let translationX = gesture.translation(in: nil).x
        let direction: CGFloat = translationX < 0 ? -1 : 1
        let shouldDismissCard = abs(translationX) > threshold
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            if shouldDismissCard {
                self.frame = .init(x: 600 * direction, y: 0, width: self.frame.width, height: self.frame.height)
            } else {
                self.transform = .identity
            }
        }, completion: { a in
            self.transform = .identity
            if shouldDismissCard {
                self.removeFromSuperview()
            }
        })
    }
}
