//
// Copyright 2025-2026 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation
@testable import MirageKit
import Testing

// MARK: - isBlank

@Suite("String - isBlank")
struct StringIsBlankTests {

    @Test("Empty string is blank")
    func emptyIsBlank() {
        #expect("".isBlank)
    }

    @Test("Whitespace only is blank")
    func whitespaceIsBlank() {
        #expect("   ".isBlank)
    }

    @Test("Newline only is blank")
    func newlineIsBlank() {
        #expect("\n".isBlank)
    }

    @Test("Tab only is blank")
    func tabIsBlank() {
        #expect("\t".isBlank)
    }

    @Test("Mixed whitespace is blank")
    func mixedWhitespaceIsBlank() {
        #expect(" \t\n ".isBlank)
    }

    @Test("Non-blank string is not blank")
    func textIsNotBlank() {
        #expect(!"hello".isBlank)
    }

    @Test("String with leading whitespace is not blank")
    func leadingWhitespaceNotBlank() {
        #expect(!"  hello".isBlank)
    }
}

// MARK: - nilIfBlank

@Suite("String - nilIfBlank")
struct StringNilIfBlankTests {

    @Test("Non-blank returns self")
    func nonBlankReturnsSelf() {
        #expect("hello".nilIfBlank == "hello")
    }

    @Test("Blank returns nil")
    func blankReturnsNil() {
        #expect("   ".nilIfBlank == nil)
    }

    @Test("Empty returns nil")
    func emptyReturnsNil() {
        #expect("".nilIfBlank == nil)
    }
}

// MARK: - Optional isBlank

@Suite("Optional String - isBlank")
struct OptionalStringIsBlankTests {

    @Test("nil is blank")
    func nilIsBlank() {
        let value: String? = nil
        #expect(value.isBlank)
    }

    @Test("Optional blank string is blank")
    func optionalBlankIsBlank() {
        let value: String? = "  "
        #expect(value.isBlank)
    }

    @Test("Optional non-blank string is not blank")
    func optionalNonBlankIsNotBlank() {
        let value: String? = "hello"
        #expect(!value.isBlank)
    }
}

// MARK: - Truncation

@Suite("String - Truncation")
struct StringTruncationTests {

    @Test("Trailing truncation adds ellipsis")
    func trailingTruncation() {
        let result = "Hello, World!".truncating(to: 5, position: .trailing)
        #expect(result == "Hello...")
    }

    @Test("Leading truncation adds ellipsis")
    func leadingTruncation() {
        let result = "Hello, World!".truncating(to: 5, position: .leading)
        #expect(result == "...orld!")
    }

    @Test("Middle truncation splits with ellipsis")
    func middleTruncation() {
        let result = "Hello, World!".truncating(to: 6, position: .middle)
        #expect(result == "Hel ... ld!")
    }

    @Test("Short string is not truncated")
    func shortStringUnchanged() {
        let result = "Hi".truncating(to: 10, position: .trailing)
        #expect(result == "Hi")
    }
}

// MARK: - Trimming

@Suite("String - Trimming")
struct StringTrimmingTests {

    @Test("trimmed removes both ends")
    func trimmedBothEnds() {
        #expect("  hello  ".trimmed() == "hello")
    }

    @Test("trimmed removes newlines")
    func trimmedNewlines() {
        #expect("\nhello\n".trimmed() == "hello")
    }

    @Test("trimmed on empty returns empty")
    func trimmedEmpty() {
        #expect("".trimmed() == "")
    }

    @Test("trimmedStart removes leading only")
    func trimmedStartLeadingOnly() {
        #expect("  hello  ".trimmedStart() == "hello  ")
    }

    @Test("trimmedStart removes leading newlines")
    func trimmedStartNewlines() {
        #expect("\n\thello".trimmedStart() == "hello")
    }

    @Test("trimmedStart on all whitespace returns empty")
    func trimmedStartAllWhitespace() {
        #expect("   ".trimmedStart() == "")
    }

    @Test("trimmedEnd removes trailing only")
    func trimmedEndTrailingOnly() {
        #expect("  hello  ".trimmedEnd() == "  hello")
    }

    @Test("trimmedEnd removes trailing newlines")
    func trimmedEndNewlines() {
        #expect("hello\n\t".trimmedEnd() == "hello")
    }

    @Test("trimmedEnd on all whitespace returns empty")
    func trimmedEndAllWhitespace() {
        #expect("   ".trimmedEnd() == "")
    }

    @Test("trimmingSuffix removes repeated suffix")
    func trimmingSuffixRepeated() {
        #expect("1.500".trimmingSuffix("0") == "1.5")
    }

    @Test("trimmingSuffix with no match returns self")
    func trimmingSuffixNoMatch() {
        #expect("hello".trimmingSuffix("x") == "hello")
    }

    @Test("trimmingSuffix removes multi-char suffix")
    func trimmingSuffixMultiChar() {
        #expect("foobarbar".trimmingSuffix("bar") == "foo")
    }
}

// MARK: - Numeric Conversion

@Suite("String - Numeric Conversion")
struct StringNumericConversionTests {

    @Test("intValue parses plain integer")
    func intValuePlain() {
        #expect("42".intValue == 42)
    }

    @Test("intValue returns nil for non-numeric")
    func intValueNonNumeric() {
        #expect("abc".intValue == nil)
    }

    @Test("intValue parses negative")
    func intValueNegative() {
        #expect("-7".intValue == -7)
    }

    @Test("doubleValue parses decimal")
    func doubleValueDecimal() {
        #expect("3.14".doubleValue == 3.14)
    }

    @Test("doubleValue returns nil for non-numeric")
    func doubleValueNonNumeric() {
        #expect("xyz".doubleValue == nil)
    }

    @Test("decimalValue parses decimal string")
    func decimalValueParsesString() {
        #expect("99.5".decimalValue != nil)
    }

    @Test("decimalValue returns nil for non-numeric")
    func decimalValueNonNumeric() {
        #expect("abc".decimalValue == nil)
    }
}

// MARK: - Collection isNotEmpty

@Suite("Collection - isNotEmpty")
struct CollectionIsNotEmptyTests {

    @Test("Non-empty array is not empty")
    func nonEmptyArray() {
        #expect([1, 2, 3].isNotEmpty)
    }

    @Test("Empty array is not isNotEmpty")
    func emptyArray() {
        #expect(![Int]().isNotEmpty)
    }

    @Test("Non-empty string is not empty")
    func nonEmptyString() {
        #expect("hello".isNotEmpty)
    }

    @Test("Empty string is not isNotEmpty")
    func emptyString() {
        #expect(!"".isNotEmpty)
    }

    @Test("Non-empty dictionary is not empty")
    func nonEmptyDict() {
        #expect(["a": 1].isNotEmpty)
    }
}

// MARK: - String Comparisons

@Suite("String - Comparisons")
struct StringComparisonTests {

    @Test("isOrderedSame case insensitive")
    func orderedSameCaseInsensitive() {
        #expect(String.isOrderedSame("Hello", "hello"))
    }

    @Test("isOrderedSame case sensitive fails on different case")
    func orderedSameCaseSensitiveFails() {
        #expect(!String.isOrderedSame("Hello", "hello", caseSensitive: true))
    }

    @Test("isOrderedAscending")
    func orderedAscending() {
        #expect(String.isOrderedAscending("apple", "banana"))
    }

    @Test("isOrderedDescending")
    func orderedDescending() {
        #expect(String.isOrderedDescending("banana", "apple"))
    }
}
