import UIKit
import SwiftUI

// MARK: - محرك حفظ وتعلم الكلمات المتكررة
class WordLearningEngine: ObservableObject {
    private let storageKey = "SwiftKeyClone_LearnedWords"
    @Published var suggestions: [String] = []
    
    // قاموس يحفظ الكلمة وعدد مرات تكرارها: [الكلمة: العدد]
    private var wordFrequencies: [String: Int] = [:]
    
    init() {
        loadWords()
        updateSuggestions(for: "")
    }
    
    private func loadWords() {
        if let saved = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] {
            wordFrequencies = saved
        } else {
            // كلمات افتراضية مبدئية
            wordFrequencies = [
                "السلام": 5, "عليكم": 5, "إن": 4, "شاء": 4,
                "الله": 6, "يعطيك": 3, "العافية": 3, "هلا": 4
            ]
            saveWords()
        }
    }
    
    private func saveWords() {
        UserDefaults.standard.set(wordFrequencies, forKey: storageKey)
    }
    
    // تسجيل الكلمة عند الانتهاء من كتابتها
    func learnWord(_ rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count > 1 else { return } // تجاهل الحروف المفردة
        
        wordFrequencies[word, default: 0] += 1
        saveWords()
    }
    
    // استخراج أفضل 3 اقتراحات بناءً على الحروف المكتوبة حالياً
    func updateSuggestions(for prefix: String) {
        let cleanPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanPrefix.isEmpty {
            // عرض أكثر 3 كلمات استخداماً بشكل عام
            suggestions = wordFrequencies
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key }
        } else {
            // عرض الكلمات المحفوظة التي تبدأ بنفس الحروف
            let matches = wordFrequencies
                .filter { $0.key.hasPrefix(cleanPrefix) }
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key }
            
            // إذا كانت الكلمة جديدة، نضعها كخيار أول لحفظها سريعاً
            if matches.isEmpty {
                suggestions = [cleanPrefix]
            } else {
                suggestions = matches
            }
        }
    }
}

// MARK: - واجهة لوحة المفاتيح (SwiftUI)
struct ArabicSwiftKeyView: View {
    @ObservedObject var engine: WordLearningEngine
    var onInsertText: (String) -> Void
    var onDeleteBackward: () -> Void
    var onSelectSuggestion: (String) -> Void
    var onNextKeyboard: () -> Void
    
    // صف الأرقام الثابت
    let numberRow = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    
    // صفوف الحروف العربية
    let row1 = ["ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج"]
    let row2 = ["ش", "س", "ي", "ب", "ل", "ا", "ت", "ن", "م", "ك", "ط"]
    let row3 = ["ذ", "ء", "ؤ", "ر", "ى", "ة", "و", "ز", "ظ", "د"]
    
    @State private var isSymbolsMode = false
    let symbolsRow1 = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
    let symbolsRow2 = ["-", "_", "+", "=", "/", "؟", "،", "؛", ":", "\""]
    
    var body: some View {
        VStack(spacing: 6) {
            // 1. شريط التنبؤ بالكلمات المحفوظة (أعلى اللوحة)
            HStack(spacing: 8) {
                ForEach(engine.suggestions, id: \.self) { word in
                    Button(action: {
                        onSelectSuggestion(word)
                    }) {
                        Text(word)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            
            // 2. صف الأرقام العلوي الدائم
            HStack(spacing: 4) {
                ForEach(numberRow, id: \.self) { num in
                    KeyButton(label: num) {
                        onInsertText(num)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // 3. صفوف الحروف أو الرموز
            if !isSymbolsMode {
                KeyRowView(keys: row1, onTap: onInsertText)
                KeyRowView(keys: row2, onTap: onInsertText)
                
                HStack(spacing: 4) {
                    ForEach(row3, id: \.self) { char in
                        KeyButton(label: char) {
                            onInsertText(char)
                        }
                    }
                    // زر الحذف
                    Button(action: onDeleteBackward) {
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 42, height: 42)
                            .background(Color(UIColor.systemGray3))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 4)
            } else {
                KeyRowView(keys: symbolsRow1, onTap: onInsertText)
                KeyRowView(keys: symbolsRow2, onTap: onInsertText)
                HStack(spacing: 4) {
                    KeyButton(label: ".") { onInsertText(".") }
                    KeyButton(label: "أ") { onInsertText("أ") }
                    KeyButton(label: "إ") { onInsertText("إ") }
                    KeyButton(label: "آ") { onInsertText("آ") }
                    KeyButton(label: "ئ") { onInsertText("ئ") }
                    Button(action: onDeleteBackward) {
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 55, height: 42)
                            .background(Color(UIColor.systemGray3))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // 4. الصف السفلي (الرموز، تغيير اللوحة، المسافة، الإدخال)
            HStack(spacing: 6) {
                // زر التبديل للرموز والهمزات
                Button(action: { isSymbolsMode.toggle() }) {
                    Text(isSymbolsMode ? "عربي" : "همزات/رموز")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 72, height: 42)
                        .background(Color(UIColor.systemGray3))
                        .cornerRadius(6)
                }
                
                // زر تغيير لوحة المفاتيح (الكرة الأرضية)
                Button(action: onNextKeyboard) {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 42)
                        .background(Color(UIColor.systemGray3))
                        .cornerRadius(6)
                }
                
                // زر المسافة
                Button(action: { onInsertText(" ") }) {
                    Text("مسافة")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.15), radius: 0.5, x: 0, y: 1)
                }
                
                // زر الإدخال
                Button(action: { onInsertText("\n") }) {
                    Text("إدخال")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 68, height: 42)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}

// مكون فرعي لصف الأزرار
struct KeyRowView: View {
    let keys: [String]
    let onTap: (String) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                KeyButton(label: key) {
                    onTap(key)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// مكون فرعي للزر الواحد
struct KeyButton: View {
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.15), radius: 0.5, x: 0, y: 1)
        }
    }
}

// MARK: - المتحكم الرئيسي للوحة المفاتيح (UIInputViewController)
class KeyboardViewController: UIInputViewController {
    private let engine = WordLearningEngine()
    private var hostingController: UIHostingController<ArabicSwiftKeyView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardUI()
    }
    
    private func setupKeyboardUI() {
        let keyboardView = ArabicSwiftKeyView(
            engine: engine,
            onInsertText: { [weak self] text in
                self?.handleInsertText(text)
            },
            onDeleteBackward: { [weak self] in
                self?.handleDelete()
            },
            onSelectSuggestion: { [weak self] word in
                self?.handleSelectSuggestion(word)
            },
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            }
        )
        
        let host = UIHostingController(rootView: keyboardView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        
        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.heightAnchor.constraint(equalToConstant: 290) // ارتفاع مثالي مع صف الأرقام وشريط التنبؤ
        ])
        
        self.hostingController = host
    }
    
    // استخراج الكلمة التي يكتبها المستخدم حالياً قبل المؤشر
    private func currentTypedWord() -> String {
        guard let context = textDocumentProxy.documentContextBeforeInput else { return "" }
        if let lastCharacter = context.last, lastCharacter.isWhitespace || lastCharacter.isNewline {
            return ""
        }
        let components = context.components(separatedBy: .whitespacesAndNewlines)
        return components.last ?? ""
    }
    
    private func handleInsertText(_ text: String) {
        // إذا ضغط مسافة أو سطر جديد، نحفظ الكلمة التي قبلها في القاموس
        if text == " " || text == "\n" {
            let wordToLearn = currentTypedWord()
            engine.learnWord(wordToLearn)
        }
        
        textDocumentProxy.insertText(text)
        engine.updateSuggestions(for: currentTypedWord())
    }
    
    private func handleDelete() {
        textDocumentProxy.deleteBackward()
        engine.updateSuggestions(for: currentTypedWord())
    }
    
    private func handleSelectSuggestion(_ suggestion: String) {
        let current = currentTypedWord()
        // حذف الحروف المكتوبة جزئياً واستبدالها بالكلمة الكاملة
        for _ in 0..<current.count {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(suggestion + " ")
        engine.learnWord(suggestion)
        engine.updateSuggestions(for: "")
    }
}
