![](meta/icon.png)

## High Performance UTF8 for Swift

Consider Hitch as an alternative to String.

```
+-------------------------------+--------------------------+
|HitchPerformanceTests.swift    |    Faster than String    |
+-------------------------------+--------------------------+
|string iterator                |         5718.35x         |
|utf8 iterator                  |          94.80x          |
|last index of                  |          40.68x          |
|first index of                 |          18.72x          |
|contains                       |          14.38x          |
|uppercase/lowercase            |          14.25x          |
|replace occurrences of         |          10.64x          |
|append (dynamic capacity)      |          5.64x           |
|append (static capacity)       |          1.14x           |
+-------------------------------+--------------------------+
```

## Usage

The guiding vision for Hitch is to **help ensure you are always on the fastest path** for UTF8 string processing. It aims to be **blatantly transparent** about hidden copy operations that can slow you down unintentionally.

A **Hitch** is a reference type which holds UTF8 buffer data; think of it as a **hybrid of NSString and String**. It is a **class**, it can point to **shared mutable or immutable data**, and it has **copyOnWrite disabled** by default.

A **HalfHitch** is a value type which points to existing, immuable UTF8 data. If possible, it will retain the original source it is pointing to.  

*Note: HalfHitch.unescape() is the one exception to this, which will allow you to unescape unicode in place if the HalfHitch is pointing to a section of mutable data. It is coded to fatal error if you attempt to call it on immutable data.*

The **Hitchable** protocol provides all of the immutable funcationality shared between **Hitches** and **HalfHitches**. You could conform to it for your own structures to provide said functionality to any arbitrary UTF8 data.

As an example of this, prior to v0.4.0 Hitch's implementation ExpressibleByStringLiteral would result in n opaque copy of the underlying data. Now ExpressibleByStringLiteral is only allowed for StaticString (ie a string literal), where the resulting Hitchable can point to the raw, unmutable strind data.

By default, Hitchables which are generated off of StaticStrings have "copyOnWrite" disabled. This means that attempting call a mutating method on a Hitch created from the StaticString will result in a fatal error. You can enabled copyOnWrite, in which case calling a mutating method on the Hitch will result in a new, mutable data store to be created prior to the mutation taking place.


## Format Strings

Hitch has its own high performance formatted strings.  It works like this:

**Example:**

```swift
let halfHitch = "{0} {1}" << ["hello", "world"]
let hitch = "{0} {1}" <<< ["hello", "world"]
    
XCTAssertEqual(halfHitch, "hello world")
XCTAssertEqual(hitch, "hello world")
```

**Example:**

```swift
let value = Hitch("""
    {0}
    +----------+----------+----------+
    |{-??     }|{~?      }|{?       }|
    |{-?      }|{~?      }|{+?      }|
    |{-?.2    }|{~8.3    }|{+?.1    }|
    |{-1      }|{~2      }|{1       }|
    +----------+----------+----------+
    {{we no longer escape braces}}
    {These don't need to be escaped because they contain invalid characters}
    """, "This is an unbounded field", "Hello", "World", 27, 1, 2, 3, 1.0/3.0, 543.0/23.0, 99999.99999)
print(value)
```

**Output:**

```
This is an unbounded field
+----------+----------+----------+
|Hello     |  World   |        27|
|1         |    2     |         3|
|0.33      |  23.608  |      23.6|
|Hello     |  World   |     Hello|
+----------+----------+----------+
{{we no longer escape braces}}
{These don't need to be escaped because they contain invalid characters}
```

**An unbounded field**  
is defined by ```{0}``` with no spaces or other formatting.

**Field width**  
is defined by the amount of space between the opening ```{``` and the closing ```}```. As you can see in the example above, this makes everything visually line up in the format string.

**Left justification**  
is defined by a ```-``` sign, such as ```{-0     }```. The sign can appear anywhere in the field, such as ```{  0  -  }```

**Center justification**  
is defined by a ```~``` sign, such as ```{~0     }``` The sign can appear anywhere in the field, such as ```{~    0  }```

**Right justification**  
is defined by a ```+``` sign, such as ```{+0     }``` The sign can appear anywhere in the field, such as ```{  0    +}```

**Unnamed value indexes**  
are allowed by using a ```?```.  This value starts at 0, and is incremented after every ```?``` encountered inside of a ```{}```. So ```"{???     }"``` is valid, you will get the ```2``` indexed value in this field.

**Braces can still be used normally;**  
if illegal characters exist inside of a brace, or the braces fail to contain the required information for formatting, then they are interpretted as is.

**Floating point precision**  
is defined by placing ```.``` after the value index, followed by the number of precision digits. For example, ```{-?.4  }``` means "left aligned using the next value index with four points of decimal precision with a field width of 8"

## Hitch License

Hitch is free software distributed under the terms of the MIT license, reproduced below. Hitch may be used for any purpose, including commercial purposes, at absolutely no cost. No paperwork, no royalties, no GNU-like "copyleft" restrictions. Just download and enjoy.

Copyright (c) 2020 [Chimera Software, LLC](http://www.chimerasw.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
