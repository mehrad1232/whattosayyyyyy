import UIKit

private enum KeyStyle {
    case number
    case function
    case operation
    case equals
}

private struct CalculatorKey {
    let title: String
    let identifier: String
    let style: KeyStyle
}

final class CalculatorViewController: UIViewController {
    private let backgroundGradient = CAGradientLayer()
    private let rootStack = UIStackView()
    private let leftPanel = UIStackView()
    private let header = UIStackView()
    private let displayCard = UIView()
    private let displayTitle = UILabel()
    private let expressionLabel = UILabel()
    private let resultLabel = UILabel()
    private let keypad = UIStackView()
    private let footer = UIStackView()
    private let exactBadge = UILabel()
    private var keyHeightConstraints: [NSLayoutConstraint] = []
    private var displayHeightConstraint: NSLayoutConstraint!
    private var landscapeKeypadWidthConstraint: NSLayoutConstraint!
    private var currentLayoutIsLandscape: Bool?
    private var keyButtons: [UIButton] = []

    private var currentEntry = "0"
    private var storedOperand: BigInteger?
    private var activeOperator: String?
    private var waitingForNewNumber = false
    private var justFinished = false
    private var errorMessage: String?

    private let operatorSymbols = ["+": "+", "-": "−", "*": "×", "/": "÷"]

    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.semanticContentAttribute = .forceLeftToRight
        buildInterface()
        refreshDisplay()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        let isLandscape = view.bounds.width > view.bounds.height
        if currentLayoutIsLandscape != isLandscape {
            configureLayout(forLandscape: isLandscape)
        }
        let glow1 = view.viewWithTag(901)
        let glow2 = view.viewWithTag(902)
        glow1?.frame = CGRect(x: -80, y: -90, width: 235, height: 235)
        glow2?.frame = CGRect(x: view.bounds.width - 150, y: view.bounds.height - 160, width: 235, height: 235)
        if let logo = view.viewWithTag(910),
           let logoGradient = logo.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            logoGradient.frame = logo.bounds
        }
    }

    private func buildInterface() {
        view.backgroundColor = UIColor(hex: 0x090B14)
        backgroundGradient.colors = [
            UIColor(hex: 0x11162A).cgColor,
            UIColor(hex: 0x090B14).cgColor,
            UIColor(hex: 0x0C1220).cgColor
        ]
        backgroundGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(backgroundGradient, at: 0)

        let glow1 = UIView()
        glow1.tag = 901
        glow1.backgroundColor = UIColor(hex: 0x7047F5).withAlphaComponent(0.18)
        glow1.layer.cornerRadius = 117
        glow1.layer.shadowColor = UIColor(hex: 0x7047F5).cgColor
        glow1.layer.shadowOpacity = 0.5
        glow1.layer.shadowRadius = 55
        view.addSubview(glow1)

        let glow2 = UIView()
        glow2.tag = 902
        glow2.backgroundColor = UIColor(hex: 0x17CDD3).withAlphaComponent(0.10)
        glow2.layer.cornerRadius = 117
        glow2.layer.shadowColor = UIColor(hex: 0x17CDD3).cgColor
        glow2.layer.shadowOpacity = 0.45
        glow2.layer.shadowRadius = 52
        view.addSubview(glow2)

        setupHeader()
        setupDisplay()
        setupKeypad()
        setupFooter()

        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.distribution = .fill
        rootStack.spacing = 10
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 15),
            rootStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -15),
            rootStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            rootStack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12)
        ])

        displayHeightConstraint = displayCard.heightAnchor.constraint(equalToConstant: 126)
        displayHeightConstraint.isActive = true

        landscapeKeypadWidthConstraint = keypad.widthAnchor.constraint(equalTo: rootStack.widthAnchor, multiplier: 0.60)
    }

    private func setupHeader() {
        let logo = UIView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.layer.cornerRadius = 14
        logo.layer.masksToBounds = true
        let logoGradient = CAGradientLayer()
        logoGradient.colors = [
            UIColor(hex: 0x9B6BFF).cgColor,
            UIColor(hex: 0x6655F5).cgColor,
            UIColor(hex: 0x31DDE0).cgColor
        ]
        logoGradient.startPoint = CGPoint(x: 0, y: 0)
        logoGradient.endPoint = CGPoint(x: 1, y: 1)
        logo.layer.addSublayer(logoGradient)
        logo.tag = 910
        logo.widthAnchor.constraint(equalToConstant: 42).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let n = UILabel()
        n.text = "N"
        n.font = UIFont.systemFont(ofSize: 24, weight: .black)
        n.textColor = .white
        n.textAlignment = .center
        n.translatesAutoresizingMaskIntoConstraints = false
        logo.addSubview(n)
        NSLayoutConstraint.activate([
            n.leadingAnchor.constraint(equalTo: logo.leadingAnchor),
            n.trailingAnchor.constraint(equalTo: logo.trailingAnchor),
            n.topAnchor.constraint(equalTo: logo.topAnchor),
            n.bottomAnchor.constraint(equalTo: logo.bottomAnchor)
        ])

        let name = UILabel()
        name.text = "N O V A"
        name.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        name.textColor = UIColor(hex: 0xF7F7FF)
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.8

        let subtitle = UILabel()
        subtitle.text = "SMART CALCULATOR"
        subtitle.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
        subtitle.textColor = UIColor(hex: 0x8791AF)
        subtitle.attributedText = NSAttributedString(
            string: "SMART CALCULATOR",
            attributes: [.kern: 1.5, .foregroundColor: UIColor(hex: 0x8791AF)]
        )

        let brandText = UIStackView(arrangedSubviews: [name, subtitle])
        brandText.axis = .vertical
        brandText.alignment = .leading
        brandText.spacing = 3

        let brand = UIStackView(arrangedSubviews: [logo, brandText])
        brand.axis = .horizontal
        brand.alignment = .center
        brand.spacing = 10

        exactBadge.text = "EXACT MODE"
        exactBadge.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        exactBadge.textAlignment = .center
        exactBadge.textColor = UIColor(hex: 0x92FFF0)
        exactBadge.backgroundColor = UIColor(hex: 0x143336).withAlphaComponent(0.75)
        exactBadge.layer.cornerRadius = 10
        exactBadge.layer.masksToBounds = true
        exactBadge.layer.borderWidth = 1
        exactBadge.layer.borderColor = UIColor(hex: 0x37E4D8).withAlphaComponent(0.27).cgColor
        exactBadge.translatesAutoresizingMaskIntoConstraints = false
        exactBadge.widthAnchor.constraint(equalToConstant: 86).isActive = true
        exactBadge.heightAnchor.constraint(equalToConstant: 28).isActive = true

        header.axis = .horizontal
        header.alignment = .center
        header.distribution = .equalSpacing
        header.addArrangedSubview(brand)
        header.addArrangedSubview(exactBadge)
    }

    private func setupDisplay() {
        displayCard.backgroundColor = UIColor(hex: 0x0D1120).withAlphaComponent(0.94)
        displayCard.layer.cornerRadius = 23
        displayCard.layer.borderWidth = 1
        displayCard.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        displayCard.layer.shadowColor = UIColor.black.cgColor
        displayCard.layer.shadowOpacity = 0.18
        displayCard.layer.shadowRadius = 15
        displayCard.layer.shadowOffset = CGSize(width: 0, height: 7)
        displayCard.translatesAutoresizingMaskIntoConstraints = false

        displayTitle.text = "YOUR CALCULATION"
        displayTitle.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        displayTitle.textColor = UIColor(hex: 0x66718F)
        displayTitle.textAlignment = .right
        displayTitle.attributedText = NSAttributedString(
            string: "YOUR CALCULATION",
            attributes: [.kern: 1.35, .foregroundColor: UIColor(hex: 0x66718F)]
        )

        expressionLabel.text = "EXACT INTEGER ENGINE"
        expressionLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        expressionLabel.textColor = UIColor(hex: 0xA5AEC9)
        expressionLabel.textAlignment = .right
        expressionLabel.adjustsFontSizeToFitWidth = true
        expressionLabel.minimumScaleFactor = 0.55
        expressionLabel.lineBreakMode = .byClipping

        resultLabel.text = "0"
        resultLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 45, weight: .bold)
        resultLabel.textColor = UIColor(hex: 0xF7F8FF)
        resultLabel.textAlignment = .right
        resultLabel.adjustsFontSizeToFitWidth = true
        resultLabel.minimumScaleFactor = 0.28
        resultLabel.baselineAdjustment = .alignCenters
        resultLabel.lineBreakMode = .byClipping

        let values = UIStackView(arrangedSubviews: [displayTitle, expressionLabel, resultLabel])
        values.axis = .vertical
        values.alignment = .fill
        values.distribution = .fill
        values.spacing = 8
        values.translatesAutoresizingMaskIntoConstraints = false
        displayCard.addSubview(values)

        NSLayoutConstraint.activate([
            values.leadingAnchor.constraint(equalTo: displayCard.leadingAnchor, constant: 17),
            values.trailingAnchor.constraint(equalTo: displayCard.trailingAnchor, constant: -17),
            values.topAnchor.constraint(equalTo: displayCard.topAnchor, constant: 14),
            values.bottomAnchor.constraint(equalTo: displayCard.bottomAnchor, constant: -13)
        ])
    }

    private func setupKeypad() {
        keypad.axis = .vertical
        keypad.alignment = .fill
        keypad.distribution = .fill
        keypad.spacing = 7
        keypad.translatesAutoresizingMaskIntoConstraints = false

        let rows: [[CalculatorKey]] = [
            [
                CalculatorKey(title: "AC", identifier: "clear", style: .function),
                CalculatorKey(title: "±", identifier: "sign", style: .function),
                CalculatorKey(title: "⌫", identifier: "backspace", style: .function),
                CalculatorKey(title: "÷", identifier: "op:/", style: .operation)
            ],
            [
                CalculatorKey(title: "7", identifier: "digit:7", style: .number),
                CalculatorKey(title: "8", identifier: "digit:8", style: .number),
                CalculatorKey(title: "9", identifier: "digit:9", style: .number),
                CalculatorKey(title: "×", identifier: "op:*", style: .operation)
            ],
            [
                CalculatorKey(title: "4", identifier: "digit:4", style: .number),
                CalculatorKey(title: "5", identifier: "digit:5", style: .number),
                CalculatorKey(title: "6", identifier: "digit:6", style: .number),
                CalculatorKey(title: "−", identifier: "op:-", style: .operation)
            ],
            [
                CalculatorKey(title: "1", identifier: "digit:1", style: .number),
                CalculatorKey(title: "2", identifier: "digit:2", style: .number),
                CalculatorKey(title: "3", identifier: "digit:3", style: .number),
                CalculatorKey(title: "+", identifier: "op:+", style: .operation)
            ]
        ]

        for row in rows {
            let rowStack = makeRow()
            for key in row {
                rowStack.addArrangedSubview(makeButton(key))
            }
            keypad.addArrangedSubview(rowStack)
        }

        let bottomRow = makeRow()
        bottomRow.distribution = .fill
        let zero = makeButton(CalculatorKey(title: "0", identifier: "digit:0", style: .number))
        let clearEntry = makeButton(CalculatorKey(title: "C", identifier: "clearEntry", style: .function))
        let equals = makeButton(CalculatorKey(title: "=", identifier: "equals", style: .equals))
        zero.widthAnchor.constraint(equalTo: clearEntry.widthAnchor, multiplier: 2, constant: 7).isActive = true
        equals.widthAnchor.constraint(equalTo: clearEntry.widthAnchor).isActive = true
        bottomRow.addArrangedSubview(zero)
        bottomRow.addArrangedSubview(clearEntry)
        bottomRow.addArrangedSubview(equals)
        keypad.addArrangedSubview(bottomRow)
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 7
        return row
    }

    private func makeButton(_ key: CalculatorKey) -> UIButton {
        let button = CalculatorKeyButton(type: .custom)
        button.setTitle(key.title, for: .normal)
        button.accessibilityIdentifier = key.identifier
        button.accessibilityLabel = key.title
        button.titleLabel?.font = UIFont.systemFont(ofSize: key.style == .equals ? 26 : 20, weight: .semibold)
        button.layer.cornerRadius = 17
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.055).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = key.style == .equals ? 12 : 6
        button.layer.shadowOpacity = key.style == .equals ? 0.28 : 0.12

        switch key.style {
        case .number:
            button.backgroundColor = UIColor(hex: 0x242A40)
            button.setTitleColor(UIColor(hex: 0xF4F5FF), for: .normal)
            button.layer.shadowColor = UIColor.black.cgColor
        case .function:
            button.backgroundColor = UIColor(hex: 0x30364B)
            button.setTitleColor(UIColor(hex: 0xCBD2E8), for: .normal)
            button.layer.shadowColor = UIColor.black.cgColor
        case .operation:
            button.backgroundColor = UIColor(hex: 0x392F62)
            button.setTitleColor(UIColor(hex: 0xDCD2FF), for: .normal)
            button.layer.borderColor = UIColor(hex: 0x9B83FF).withAlphaComponent(0.25).cgColor
            button.layer.shadowColor = UIColor(hex: 0x795AF0).cgColor
        case .equals:
            button.backgroundColor = UIColor(hex: 0x7655F5)
            button.setTitleColor(.white, for: .normal)
            button.layer.borderColor = UIColor(hex: 0xC4B5FD).withAlphaComponent(0.45).cgColor
            button.layer.shadowColor = UIColor(hex: 0x7655F5).cgColor
        }

        button.translatesAutoresizingMaskIntoConstraints = false
        keyHeightConstraints.append(button.heightAnchor.constraint(equalToConstant: 48))
        keyHeightConstraints.last?.isActive = true
        button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        keyButtons.append(button)
        return button
    }

    private func setupFooter() {
        let left = UILabel()
        left.text = "●  READY TO CALCULATE"
        left.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        left.textColor = UIColor(hex: 0x69738F)
        left.attributedText = NSAttributedString(
            string: "●  READY TO CALCULATE",
            attributes: [.kern: 0.7, .foregroundColor: UIColor(hex: 0x69738F)]
        )

        let right = UILabel()
        right.text = "NO ROUNDING"
        right.font = UIFont.systemFont(ofSize: 8, weight: .bold)
        right.textColor = UIColor(hex: 0x69738F)
        right.textAlignment = .right
        right.attributedText = NSAttributedString(
            string: "NO ROUNDING",
            attributes: [.kern: 0.8, .foregroundColor: UIColor(hex: 0x69738F)]
        )

        footer.axis = .horizontal
        footer.alignment = .center
        footer.distribution = .equalSpacing
        footer.addArrangedSubview(left)
        footer.addArrangedSubview(right)
    }

    private func configureLayout(forLandscape landscape: Bool) {
        currentLayoutIsLandscape = landscape

        for stack in [rootStack, leftPanel] {
            for arranged in stack.arrangedSubviews {
                stack.removeArrangedSubview(arranged)
                arranged.removeFromSuperview()
            }
        }

        if landscape {
            leftPanel.axis = .vertical
            leftPanel.alignment = .fill
            leftPanel.distribution = .fill
            leftPanel.spacing = 10
            leftPanel.addArrangedSubview(header)
            leftPanel.addArrangedSubview(displayCard)

            rootStack.axis = .horizontal
            rootStack.alignment = .fill
            rootStack.distribution = .fill
            rootStack.spacing = 12
            rootStack.addArrangedSubview(leftPanel)
            rootStack.addArrangedSubview(keypad)
            landscapeKeypadWidthConstraint.isActive = true
            displayHeightConstraint.constant = 112
            displayTitle.font = UIFont.systemFont(ofSize: 8, weight: .bold)
            expressionLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            resultLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 31, weight: .bold)
            rootStack.spacing = 12
            keyHeightConstraints.forEach { $0.constant = 34 }
            footer.removeFromSuperview()
        } else {
            landscapeKeypadWidthConstraint.isActive = false
            rootStack.axis = .vertical
            rootStack.alignment = .fill
            rootStack.distribution = .fill
            rootStack.spacing = 9
            rootStack.addArrangedSubview(header)
            rootStack.addArrangedSubview(displayCard)
            rootStack.addArrangedSubview(keypad)
            rootStack.addArrangedSubview(footer)
            displayHeightConstraint.constant = 126
            displayTitle.font = UIFont.systemFont(ofSize: 9, weight: .bold)
            expressionLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            resultLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 45, weight: .bold)
            keyHeightConstraints.forEach { $0.constant = 48 }
        }

        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.10, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            sender.alpha = 0.84
        }, completion: { _ in
            UIView.animate(withDuration: 0.14) {
                sender.transform = .identity
                sender.alpha = 1
            }
        })

        guard let identifier = sender.accessibilityIdentifier else { return }
        if identifier.hasPrefix("digit:") {
            appendDigit(String(identifier.dropFirst("digit:".count)))
        } else if identifier.hasPrefix("op:") {
            chooseOperator(String(identifier.dropFirst("op:".count)))
        } else {
            switch identifier {
            case "clear": clearAll()
            case "clearEntry": clearEntry()
            case "sign": toggleSign()
            case "backspace": backspace()
            case "equals": performEquals()
            default: break
            }
        }
    }

    private func appendDigit(_ digit: String) {
        if errorMessage != nil {
            clearAll()
        }
        if justFinished {
            currentEntry = digit
            storedOperand = nil
            activeOperator = nil
            waitingForNewNumber = false
            justFinished = false
        } else if waitingForNewNumber {
            currentEntry = digit
            waitingForNewNumber = false
        } else if currentEntry == "0" {
            currentEntry = digit
        } else if currentEntry == "-0" {
            currentEntry = "-" + digit
        } else if currentEntry.filter({ $0 >= "0" && $0 <= "9" }).count < 120 {
            currentEntry += digit
        }
        refreshDisplay()
    }

    private func chooseOperator(_ operation: String) {
        guard errorMessage == nil else { return }

        if activeOperator != nil && waitingForNewNumber {
            activeOperator = operation
            refreshDisplay(expression: formatted(storedOperand ?? BigInteger(currentEntry)) + " " + symbol(operation))
            return
        }

        if let first = storedOperand, let pending = activeOperator {
            guard let result = apply(first, pending, BigInteger(currentEntry)) else { return }
            currentEntry = result.description
            storedOperand = result
        } else {
            storedOperand = BigInteger(currentEntry)
        }

        activeOperator = operation
        waitingForNewNumber = true
        justFinished = false
        refreshDisplay(expression: formatted(storedOperand ?? BigInteger(currentEntry)) + " " + symbol(operation))
        animateResult()
    }

    private func performEquals() {
        guard errorMessage == nil,
              let first = storedOperand,
              let operation = activeOperator else { return }

        let second = BigInteger(currentEntry)
        guard let answer = apply(first, operation, second) else { return }
        let expression = "\(formatted(first)) \(symbol(operation)) \(formatted(second)) ="
        currentEntry = answer.description
        storedOperand = nil
        activeOperator = nil
        waitingForNewNumber = false
        justFinished = true
        refreshDisplay(expression: expression)
        animateResult()
    }

    private func apply(_ first: BigInteger, _ operation: String, _ second: BigInteger) -> BigInteger? {
        switch operation {
        case "+": return first + second
        case "-": return first - second
        case "*": return first.multiplied(by: second)
        case "/":
            guard let value = first.divided(by: second) else {
                errorMessage = "Cannot divide by zero"
                expressionLabel.text = "MATH ERROR"
                resultLabel.text = "Cannot divide by zero"
                resultLabel.textColor = UIColor(hex: 0xFF8C9A)
                storedOperand = nil
                activeOperator = nil
                waitingForNewNumber = true
                justFinished = true
                refreshDisplay()
                return nil
            }
            return value
        default: return nil
        }
    }

    private func toggleSign() {
        if errorMessage != nil { clearAll() }
        if currentEntry == "0" { currentEntry = "-0" }
        else if currentEntry == "-0" { currentEntry = "0" }
        else if currentEntry.hasPrefix("-") { currentEntry.removeFirst() }
        else { currentEntry = "-" + currentEntry }
        waitingForNewNumber = false
        justFinished = false
        refreshDisplay()
    }

    private func backspace() {
        if errorMessage != nil { clearAll(); return }
        if currentEntry.count > 1 {
            currentEntry.removeLast()
            if currentEntry == "-" { currentEntry = "0" }
        } else {
            currentEntry = "0"
        }
        waitingForNewNumber = false
        justFinished = false
        refreshDisplay()
    }

    private func clearEntry() {
        currentEntry = "0"
        errorMessage = nil
        waitingForNewNumber = false
        justFinished = false
        resultLabel.textColor = UIColor(hex: 0xF7F8FF)
        refreshDisplay()
    }

    private func clearAll() {
        currentEntry = "0"
        storedOperand = nil
        activeOperator = nil
        waitingForNewNumber = false
        justFinished = false
        errorMessage = nil
        resultLabel.textColor = UIColor(hex: 0xF7F8FF)
        refreshDisplay(expression: "EXACT INTEGER ENGINE")
    }

    private func refreshDisplay(expression: String? = nil) {
        if let error = errorMessage {
            expressionLabel.text = "MATH ERROR"
            resultLabel.text = error
            resultLabel.textColor = UIColor(hex: 0xFF8C9A)
            resultLabel.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
            return
        }

        resultLabel.textColor = UIColor(hex: 0xF7F8FF)
        let resultFontSize: CGFloat = (currentLayoutIsLandscape ?? false) ? 31 : 45
        resultLabel.font = UIFont.monospacedDigitSystemFont(ofSize: resultFontSize, weight: .bold)
        resultLabel.text = formatted(BigInteger(currentEntry))

        if let expression = expression {
            expressionLabel.text = expression
        } else if let first = storedOperand, let operation = activeOperator {
            if waitingForNewNumber {
                expressionLabel.text = "\(formatted(first)) \(symbol(operation))"
            } else {
                expressionLabel.text = "\(formatted(first)) \(symbol(operation)) \(formatted(BigInteger(currentEntry)))"
            }
        } else if !justFinished {
            expressionLabel.text = currentEntry == "0" ? "EXACT INTEGER ENGINE" : "INTEGER INPUT · READY"
        }
    }

    private func symbol(_ operation: String) -> String {
        return operatorSymbols[operation] ?? operation
    }

    private func formatted(_ value: BigInteger) -> String {
        let raw = value.description
        let negative = raw.hasPrefix("-")
        let digits = negative ? String(raw.dropFirst()) : raw
        let reversed = Array(digits.reversed())
        var chunks: [String] = []
        var start = 0
        while start < reversed.count {
            let end = min(start + 3, reversed.count)
            chunks.append(String(Array(reversed[start..<end].reversed())))
            start = end
        }
        let body = chunks.reversed().joined(separator: ",")
        if raw == "-0" { return "−0" }
        return (negative ? "−" : "") + body
    }

    private func animateResult() {
        resultLabel.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        resultLabel.alpha = 0.65
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.resultLabel.transform = .identity
            self.resultLabel.alpha = 1
        }, completion: nil)
    }
}

private final class CalculatorKeyButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
                self.alpha = self.isHighlighted ? 0.86 : 1
            }, completion: nil)
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
