//
//  Editor.swift
//  z80play
//
//  Created by German Laullon on 14/11/23.
//

import SwiftUI

fileprivate let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
fileprivate let validLineAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: NSColor.black] as [NSAttributedString.Key : Any]
fileprivate let errorLineAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: NSColor.red] as [NSAttributedString.Key : Any]
fileprivate let lineNumberAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: NSColor.darkGray] as [NSAttributedString.Key : Any]
fileprivate let commentLineAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: NSColor.darkGray] as [NSAttributedString.Key : Any]
fileprivate let labelLineAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: NSColor.blue] as [NSAttributedString.Key : Any]
fileprivate let nextLineAttributes = [NSAttributedString.Key.backgroundColor: NSColor.green] as [NSAttributedString.Key : Any]

struct Editor: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var machine: Machine

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        let lineNumberView = LineNumberRulerView(textView: textView, machine: machine)
        lineNumberView.clipsToBounds = true
        
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        scrollView.hasHorizontalScroller = true
        
        textView.maxSize = NSMakeSize(.greatestFiniteMagnitude, .greatestFiniteMagnitude)
        textView.isHorizontallyResizable = true
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        
        textView.textStorage?.append(NSAttributedString(string: text,attributes: validLineAttributes))

        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSMakeSize(.greatestFiniteMagnitude, .greatestFiniteMagnitude)

        context.coordinator.scrollView = scrollView
        context.coordinator.lineNumberView = lineNumberView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let lineNumberView = context.coordinator.lineNumberView else {
            return
        }
        
        guard let textView = context.coordinator.scrollView!.documentView as? NSTextView else {
            return
        }
        
        guard let text = textView.textStorage else {
            return
        }
        
        text.beginEditing()
        let code = text.string
        text.setAttributes(validLineAttributes, range: NSMakeRange(0, code.count))
        for (i, line) in code.split(separator: "\n",omittingEmptySubsequences: false).enumerated() {
            if machine.ops.indices.contains(i) {
                let r = NSRange(line.startIndex..<line.endIndex, in: code)
                if !machine.ops[i].valid {
                    text.setAttributes(errorLineAttributes, range: r)
                } else{
                    if machine.ops[i].inst is Label {
                        text.setAttributes(labelLineAttributes, range: r)
                    } else if machine.ops[i].inst is Void {
                        text.setAttributes(commentLineAttributes, range: r)
                    }

                }
            }
        }
        text.endEditing()
        
        lineNumberView.needsDisplay = true
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: Editor
        var scrollView: NSScrollView?
        var lineNumberView: LineNumberRulerView?
        
        init(parent: Editor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            lineNumberView?.needsDisplay = true
        }
    }
}

class LineNumberRulerView: NSRulerView {
    var machine: Machine
    private lazy var area = makeTrackingArea()
    private var hoverPoint = NSPoint.out
    private var hoverLine = Int.max
    private let pauseSymbol = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "pause")!.withSymbolConfiguration(.init(paletteColors: [.black, .lightGray]))!
    private let pauseSymbol_h = NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "pause")!
    private let pauseSymbol_s = NSImage(systemSymbolName: "pause.circle.fill", accessibilityDescription: "pause")!

    private let eyeSymbol = NSImage(systemSymbolName: "eye.circle",variableValue: 0, accessibilityDescription: "watch")!.withSymbolConfiguration(.init(paletteColors: [.black, .lightGray]))!
    private let eyeSymbol_h = NSImage(systemSymbolName: "eye.circle", accessibilityDescription: "pause")!
    private let eyeSymbol_s = NSImage(systemSymbolName: "eye.circle.fill", accessibilityDescription: "pause")!

    init(textView: NSTextView, machine: Machine) {
        self.machine = machine
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
        self.clientView = textView
        
        let testStr = NSAttributedString(string: "0x0000 00 00 00 00",
                                         attributes: [NSAttributedString.Key.font : font as Any])
        
        print("-",testStr.size().width)
        self.ruleThickness = testStr.size().width + 10
        
//        var config = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
//        config = config.applying(.init(paletteColors: [.systemTeal, .systemGray]))
//        eyeSymbol.image = eyeSymbol.withSymbolConfiguration(config)

    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func updateTrackingAreas() {
        removeTrackingArea(area)
        area = makeTrackingArea()
        addTrackingArea(area)
    }
    
    private func makeTrackingArea() -> NSTrackingArea {
        return NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
    }
    
    override func mouseMoved(with event: NSEvent) {
        hoverPoint = event.locationInWindow
        hoverPoint = self.convert(hoverPoint, from: self)
        hoverPoint.y = self.bounds.maxY - hoverPoint.y;
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        hoverLine = .max
        hoverPoint = .out
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        if machine.ops.indices.contains(hoverLine) {
            if let inst = machine.ops[hoverLine].inst as? Inst {
                inst.breakPoint.toggle()
                needsDisplay = true
            } else if let db = machine.ops[hoverLine].inst as? DB {
                db.watch.toggle()
                machine.updateWatchedMemory()
                needsDisplay = true
            }
        }
    }
    
    func drawLineNumber(_ lineNumberString:String, y:CGFloat) {
        let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
        attString.draw(at: NSPoint(x: 5, y: y))
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        hoverLine = Int.max
        if let textView = self.clientView as? NSTextView {
            if let layoutManager = textView.layoutManager {
                
                let relativePoint = self.convert(NSZeroPoint, from: textView)
                
                
                let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: textView.textContainer!)
                let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
                
                let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])
                // The line number for the first visible line
                var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
                
                var glyphIndexForStringLine = visibleGlyphRange.location
                
                // Go through each line in the string.
                while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
                    
                    // Range of current line in the string.
                    let characterRangeForStringLine = (textView.string as NSString).lineRange(
                        for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
                    )
                    let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
                    
                    var glyphIndexForGlyphLine = glyphIndexForStringLine
                    var glyphLineCount = 0
                    
                    while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
                        
                        // See if the current line in the string spread across
                        // several lines of glyphs
                        var effectiveRange = NSMakeRange(0, 0)
                        
                        // Range of current "line of glyphs". If a line is wrapped,
                        // then it will have more than one "line of glyphs"
                        let sourceRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                        var lineRect = NSMakeRect(sourceRect.minX, sourceRect.minY, ruleThickness, sourceRect.height)
                        lineRect = lineRect.offsetBy(dx: 0, dy: relativePoint.y);
                        
                        if glyphLineCount == 0 {
                            if machine.ops.indices.contains(lineNumber-1){
                                let op = machine.ops[lineNumber-1]
                                if op.valid {
                                    
                                    let imgRect = NSMakeRect(lineRect.maxX - lineRect.height, lineRect.minY, lineRect.height, lineRect.height)
                                    if NSPointInRect(hoverPoint, imgRect) {
                                        hoverLine = lineNumber-1
                                    }
                                    
                                    if let inst = op.inst as? Inst {
                                        if op.pc == machine.nextPc {
                                            NSColor.green.set()
                                            let line = NSBezierPath()
                                            line.move(to: NSPoint(x: lineRect.minX, y: lineRect.minY))
                                            line.line(to: NSPoint(x: lineRect.minX, y: lineRect.maxY))
                                            line.line(to: NSPoint(x: lineRect.maxX, y: lineRect.maxY))
                                            line.line(to: NSPoint(x: lineRect.maxX, y: lineRect.minY))
                                            line.lineWidth = 1
                                            line.fill()
                                        }
                                        
                                        if inst.breakPoint {
                                            drawIcon(in: imgRect, alpha: 0.8, icon: pauseSymbol_s)
                                        } else if NSPointInRect(hoverPoint, lineRect) {
                                            if NSPointInRect(hoverPoint, imgRect) {
                                                drawIcon(in: imgRect, alpha: 0.3, icon: pauseSymbol_h)
                                            } else {
                                                drawIcon(in: imgRect, alpha: 0.1, icon: pauseSymbol)
                                            }
                                        }
                                        
                                        drawLineNumber("\(op.dump())", y: lineRect.minY)
                                        
                                    } else if let db = op.inst as? DB {
                                        if db.watch {
                                            drawIcon(in: imgRect, alpha: 0.8, icon: eyeSymbol_s)
                                        } else if NSPointInRect(hoverPoint, lineRect) {
                                            if NSPointInRect(hoverPoint, imgRect) {
                                                drawIcon(in: imgRect, alpha: 0.3, icon: eyeSymbol_h)
                                            } else {
                                                drawIcon(in: imgRect, alpha: 0.1, icon: eyeSymbol)
                                            }
                                        }
                                        drawLineNumber("\(op.pc.toHex())", y: lineRect.minY)
                                    }
                                }
                            }
                        }
                        
                        // Move to next glyph line
                        glyphLineCount += 1
                        glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
                    }
                    
                    glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
                    lineNumber += 1
                }
            }
        }
    }
    
    private func drawPause(in rect: NSRect, alpha: Double) {
        drawIcon(in: rect, alpha: alpha, icon: pauseSymbol)
    }
    
    private func drawEye(in rect: NSRect, alpha: Double) {
        drawIcon(in: rect, alpha: alpha, icon: eyeSymbol)
    }
    
    private func drawIcon(in rect: NSRect, alpha: Double, icon: NSImage) {
//        let path = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
//        NSColor.red.withAlphaComponent(alpha).setFill()
//        path.fill()
//        NSColor.red.setStroke()
//        path.stroke()
        icon.draw(in: rect)
    }
}

extension CGPoint {
    public static var out: CGPoint { get { CGPoint(x: -1, y: -1) } }
}
