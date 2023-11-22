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
    @ObservedObject var machine: MachineStatus

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        textView.delegate = context.coordinator
        textView.textStorage?.append(NSAttributedString(string: text))

        let lineNumberView = LineNumberRulerView(textView: textView, machine: machine)
        lineNumberView.clipsToBounds = true
        
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

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
    var machine: MachineStatus

    init(textView: NSTextView, machine: MachineStatus) {
        self.machine = machine
        super.init(scrollView: textView.enclosingScrollView!, orientation: NSRulerView.Orientation.verticalRuler)
        self.clientView = textView
        
        let testStr = NSAttributedString(string: "0x0000 00 00 00 00",
                                         attributes: [NSAttributedString.Key.font : font as Any])

        self.ruleThickness = testStr.size().width + 10
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        if let textView = self.clientView as? NSTextView {
            if let layoutManager = textView.layoutManager {
                
                let relativePoint = self.convert(NSZeroPoint, from: textView)
                
                let drawLineNumber = { (lineNumberString:String, y:CGFloat) in
                    let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
                    attString.draw(at: NSPoint(x: 5, y: relativePoint.y + y))
                }
                
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
                        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndexForGlyphLine, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                        
                        if glyphLineCount > 0 {
                            drawLineNumber("", lineRect.minY)
                        } else {
                            if machine.ops.indices.contains(lineNumber-1){
                                let op = machine.ops[lineNumber-1]
                                if op.inst is Inst && op.valid {
                                    if op.pc == machine.nextPc {
                                        NSColor.green.set()
                                        let line = NSBezierPath()
                                        line.move(to: NSPoint(x: lineRect.minX, y: relativePoint.y + lineRect.minY))
                                        line.line(to: NSPoint(x: lineRect.minX, y: relativePoint.y + lineRect.maxY))
                                        line.line(to: NSPoint(x: lineRect.maxX, y: relativePoint.y + lineRect.maxY))
                                        line.line(to: NSPoint(x: lineRect.maxX, y: relativePoint.y + lineRect.minY))
                                        line.lineWidth = 1
                                        line.fill()
                                    }
                                    drawLineNumber("\(op.dump())", lineRect.minY)
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
}
