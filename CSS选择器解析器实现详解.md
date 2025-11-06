# CSS 选择器解析器实现详解

## 概述

postcss-selector-parser 是一个用于解析和操作 CSS 选择器的工具库。它将 CSS 选择器字符串转换为抽象语法树（AST），允许对选择器进行编程式的分析和修改。

## 核心架构

### 1. 整体流程

解析过程分为三个主要阶段：

```
CSS字符串 → 词法分析(Tokenization) → 语法分析(Parsing) → AST树
```

1. **词法分析（Tokenization）**：将CSS字符串分解成token流
2. **语法分析（Parsing）**：将token流转换为抽象语法树
3. **AST操作**：提供API对AST进行遍历和修改

### 2. 主要模块

- **tokenize.js**: 词法分析器，负责将字符串转换为token数组
- **parser.js**: 语法分析器，负责将token数组构建成AST
- **processor.js**: 处理器，提供统一的API接口
- **selectors/**: 各种选择器节点类型的定义

## 词法分析器（Tokenizer）

### 2.1 Token类型定义（tokenTypes.js）

词法分析器识别以下token类型：

```javascript
// 字符类型（基于ASCII码）
ampersand (&)        = 38
asterisk (*)         = 42
comma (,)            = 44
colon (:)            = 58
semicolon (;)        = 59
openParenthesis (()  = 40
closeParenthesis ())  = 41
openSquare ([)       = 91
closeSquare (])      = 93
dollar ($)           = 36
tilde (~)            = 126
caret (^)            = 94
plus (+)             = 43
equals (=)           = 61
pipe (|)             = 124
greaterThan (>)      = 62
space ( )            = 32
singleQuote (')      = 39
doubleQuote (")      = 34
slash (/)            = 47
bang (!)             = 33
backslash (\)        = 92

// 空白字符
cr (\r)              = 13
feed (\f)            = 12
newline (\n)         = 10
tab (\t)             = 9

// 特殊token类型
str                  = singleQuote  // 字符串
comment              = -1            // 注释
word                 = -2            // 单词
combinator           = -3            // 组合器
```

### 2.2 Token结构

每个token是一个包含7个元素的数组：

```javascript
[
    TYPE,        // [0] Token类型
    START_LINE,  // [1] 起始行号
    START_COL,   // [2] 起始列号
    END_LINE,    // [3] 结束行号
    END_COL,     // [4] 结束列号
    START_POS,   // [5] 起始位置索引
    END_POS      // [6] 结束位置索引
]
```

### 2.3 词法分析过程

#### 2.3.1 主循环

```javascript
function tokenize(input) {
    const tokens = [];
    let css = input.css.valueOf();
    let offset = -1;
    let line = 1;
    let start = 0;
    
    while (start < css.length) {
        code = css.charCodeAt(start);
        // 根据当前字符决定如何处理
        switch (code) {
            case space:
            case tab:
            case newline:
            case cr:
            case feed:
                // 处理空白字符
                break;
            case plus:
            case greaterThan:
            case tilde:
            case pipe:
                // 处理组合器
                break;
            // ... 其他情况
        }
    }
    return tokens;
}
```

#### 2.3.2 转义序列处理

CSS支持两种转义序列：

1. **十六进制转义**：`\xxxxxx` (最多6位十六进制)
   - 如：`\000041` 表示字母 'A'
   - 少于6位时，可以用空格结束

2. **字符转义**：`\x` (转义任意字符)
   - 如：`\.` 转义点号

```javascript
function consumeEscape(css, start) {
    let next = start;
    let code = css.charCodeAt(next + 1);
    
    if (hex[code]) {
        let hexDigits = 0;
        // 消费最多6个十六进制字符
        do {
            next++;
            hexDigits++;
            code = css.charCodeAt(next + 1);
        } while (hex[code] && hexDigits < 6);
        
        // 如果少于6个十六进制字符，空格结束转义
        if (hexDigits < 6 && code === space) {
            next++;
        }
    } else {
        // 下一个字符是被转义的字符
        next++;
    }
    return next;
}
```

#### 2.3.3 单词识别

单词是由非分隔符字符组成的序列：

```javascript
function consumeWord(css, start) {
    let next = start;
    let code;
    do {
        code = css.charCodeAt(next);
        if (wordDelimiters[code]) {
            return next - 1;
        } else if (code === backslash) {
            next = consumeEscape(css, next) + 1;
        } else {
            next++;
        }
    } while (next < css.length);
    return next - 1;
}
```

#### 2.3.4 字符串处理

字符串用引号包围，支持转义：

```javascript
case singleQuote:
case doubleQuote:
    quote = code === singleQuote ? "'" : '"';
    next = start;
    do {
        escaped = false;
        next = css.indexOf(quote, next + 1);
        if (next === -1) {
            unclosed('quote', quote);
        }
        // 检查引号前的反斜杠
        escapePos = next;
        while (css.charCodeAt(escapePos - 1) === backslash) {
            escapePos -= 1;
            escaped = !escaped;
        }
    } while (escaped);
    
    tokenType = str;
    end = next + 1;
    break;
```

#### 2.3.5 注释处理

CSS注释是 `/* ... */` 格式：

```javascript
if (code === slash && css.charCodeAt(start + 1) === asterisk) {
    next = css.indexOf('*/', start + 2) + 1;
    if (next === 0) {
        unclosed('comment', '*/');
    }
    
    content = css.slice(start, next + 1);
    lines = content.split('\n');
    last = lines.length - 1;
    
    // 跟踪多行注释的行号和列号
    if (last > 0) {
        nextLine = line + last;
        nextOffset = next - lines[last].length;
    } else {
        nextLine = line;
        nextOffset = offset;
    }
    
    tokenType = comment;
    line = nextLine;
}
```

## 语法分析器（Parser）

### 3.1 AST节点类型

解析器构建的AST包含以下节点类型：

```javascript
// 节点类型常量
ROOT         // 根节点，包含所有选择器
SELECTOR     // 选择器节点，如 "div.class"
TAG          // 标签选择器，如 "div"
CLASS        // 类选择器，如 ".class"
ID           // ID选择器，如 "#id"
ATTRIBUTE    // 属性选择器，如 "[href]"
PSEUDO       // 伪类/伪元素，如 ":hover"
UNIVERSAL    // 通配符选择器 "*"
COMBINATOR   // 组合器，如 " ", ">", "+", "~"
NESTING      // 嵌套选择器 "&"
COMMENT      // 注释
STRING       // 字符串
```

### 3.2 节点基类（Node）

所有节点都继承自基类Node：

```javascript
class Node {
    constructor(opts = {}) {
        Object.assign(this, opts);
        this.spaces = this.spaces || {};
        this.spaces.before = this.spaces.before || '';
        this.spaces.after = this.spaces.after || '';
    }
    
    // 节点操作方法
    remove()           // 从父节点移除
    replaceWith()      // 替换为其他节点
    next()             // 获取下一个兄弟节点
    prev()             // 获取上一个兄弟节点
    clone()            // 克隆节点
    toString()         // 转换为字符串
}
```

节点包含以下关键属性：

- **type**: 节点类型
- **value**: 节点值
- **source**: 源码位置信息 `{start: {line, column}, end: {line, column}}`
- **sourceIndex**: 在原始CSS字符串中的起始位置
- **spaces**: 空白字符信息 `{before, after}`
- **raws**: 原始值（未转义的）

### 3.3 Parser类结构

```javascript
class Parser {
    constructor(rule, options = {}) {
        this.rule = rule;
        this.options = Object.assign({lossy: false, safe: false}, options);
        this.position = 0;
        this.css = typeof rule === 'string' ? rule : rule.selector;
        
        // 词法分析
        this.tokens = tokenize({
            css: this.css,
            error: this._errorGenerator(),
            safe: this.options.safe
        });
        
        // 创建根节点
        this.root = new Root({source: rootSource});
        
        // 创建初始选择器
        const selector = new Selector({
            source: {start: {line: 1, column: 1}},
            sourceIndex: 0
        });
        this.root.append(selector);
        this.current = selector;
        
        // 开始解析
        this.loop();
    }
}
```

### 3.4 主解析循环

```javascript
loop() {
    while (this.position < this.tokens.length) {
        this.parse(true);
    }
    this.current._inferEndPosition();
    return this.root;
}

parse(throwOnParenthesis) {
    switch (this.currToken[TYPE]) {
        case tokens.space:
            this.space();
            break;
        case tokens.comment:
            this.comment();
            break;
        case tokens.openParenthesis:
            this.parentheses();
            break;
        case tokens.openSquare:
            this.attribute();
            break;
        case tokens.word:
            this.word();
            break;
        case tokens.colon:
            this.pseudo();
            break;
        case tokens.comma:
            this.comma();
            break;
        case tokens.asterisk:
            this.universal();
            break;
        case tokens.ampersand:
            this.nesting();
            break;
        case tokens.combinator:
            this.combinator();
            break;
        // ... 其他情况
    }
}
```

### 3.5 选择器解析方法

#### 3.5.1 标签选择器（Tag）

```javascript
// 示例：div, span, h1
splitWord(namespace) {
    // 将单词分割为多个节点
    // 如 "div.class#id" 分割为 tag + class + id
    let value = this.content();
    // 按特殊字符位置分割
    // 创建相应的节点
}
```

#### 3.5.2 类选择器（Class）

```javascript
// 示例：.class, .my-class
// 在splitWord中识别点号后创建ClassName节点
node = new ClassName({
    value: value.slice(1),  // 去掉点号
    source: source,
    sourceIndex: sourceIndex
});
```

#### 3.5.3 ID选择器（ID）

```javascript
// 示例：#id, #my-id
// 在splitWord中识别井号后创建ID节点
node = new ID({
    value: value.slice(1),  // 去掉井号
    source: source,
    sourceIndex: sourceIndex
});
```

#### 3.5.4 属性选择器（Attribute）

属性选择器的语法较复杂，支持多种形式：

```css
[attr]              /* 存在属性 */
[attr="value"]      /* 完全匹配 */
[attr~="value"]     /* 包含单词 */
[attr|="value"]     /* 开头匹配（带连字符） */
[attr^="value"]     /* 前缀匹配 */
[attr$="value"]     /* 后缀匹配 */
[attr*="value"]     /* 子串匹配 */
[attr="value" i]    /* 不区分大小写 */
```

解析过程：

```javascript
attribute() {
    const attr = [];
    const startingToken = this.currToken;
    this.position++;
    
    // 收集方括号内的所有token
    while (
        this.position < this.tokens.length &&
        this.currToken[TYPE] !== tokens.closeSquare
    ) {
        attr.push(this.currToken);
        this.position++;
    }
    
    // 解析属性token
    let node = {
        source: getSource(...),
        sourceIndex: startingToken[START_POS]
    };
    
    // 状态机解析属性各部分
    let pos = 0;
    let lastAdded = null;
    
    while (pos < attr.length) {
        const token = attr[pos];
        const content = this.content(token);
        
        switch (token[TYPE]) {
            case tokens.word:
                // 属性名或命名空间
                if (next && this.content(next) === '|') {
                    node.namespace = content;
                } else {
                    node.attribute = content;
                }
                break;
            case tokens.equals:
            case tokens.asterisk:
            case tokens.dollar:
            case tokens.caret:
            case tokens.tilde:
                // 操作符
                if (next[TYPE] === tokens.equals) {
                    node.operator = content;
                }
                break;
            case tokens.str:
                // 字符串值
                node.value = unescapeValue(content);
                node.quoteMark = quote;
                break;
            // ... 其他情况
        }
        pos++;
    }
    
    this.newNode(new Attribute(node));
}
```

#### 3.5.5 伪类和伪元素（Pseudo）

```javascript
// 示例：:hover, ::before, :not(.class), :nth-child(2n+1)
pseudo() {
    let content = this.content();
    let next = this.nextToken;
    
    // 检查是否为伪元素（双冒号）
    if (next && next[TYPE] === tokens.colon) {
        // 双冒号伪元素
        this.position++;
        content = content + this.content();
    }
    
    const node = new Pseudo({
        value: content,
        source: getTokenSource(this.currToken),
        sourceIndex: this.currToken[START_POS]
    });
    
    this.newNode(node);
    this.position++;
}
```

#### 3.5.6 组合器（Combinator）

CSS支持以下组合器：

```css
" "   /* 后代选择器 */
">"   /* 子元素选择器 */
"+"   /* 相邻兄弟选择器 */
"~"   /* 通用兄弟选择器 */
```

```javascript
combinator() {
    // 处理管道符（命名空间）
    if (this.content() === '|') {
        return this.namespace();
    }
    
    // 查找下一个有意义的token
    let nextSigTokenPos = this.locateNextMeaningfulToken(this.position);
    
    // 如果后面没有有意义的token，这些空白是尾部空白
    if (nextSigTokenPos < 0 || 
        this.tokens[nextSigTokenPos][TYPE] === tokens.comma) {
        // 将空白添加到前一个节点的after空间
        return;
    }
    
    // 解析空白或组合器
    let node;
    if (this.currToken[TYPE] === tokens.combinator) {
        node = new Combinator({
            value: this.content(),
            source: getTokenSource(this.currToken),
            sourceIndex: this.currToken[START_POS]
        });
    } else {
        // 后代组合器（空白）
        node = new Combinator({
            value: ' ',
            source: getTokenSourceSpan(...),
            sourceIndex: firstToken[START_POS]
        });
    }
    
    return this.newNode(node);
}
```

#### 3.5.7 括号内容（Parentheses）

用于解析伪类函数的参数：

```javascript
parentheses() {
    let last = this.current.last;
    let unbalanced = 1;
    this.position++;
    
    if (last && last.type === PSEUDO) {
        // 伪类的参数
        const selector = new Selector({
            source: {start: tokenStart(this.tokens[this.position])},
            sourceIndex: this.tokens[this.position][START_POS]
        });
        
        const cache = this.current;
        last.append(selector);
        this.current = selector;
        
        // 解析括号内的内容
        while (this.position < this.tokens.length && unbalanced) {
            if (this.currToken[TYPE] === tokens.openParenthesis) {
                unbalanced++;
            }
            if (this.currToken[TYPE] === tokens.closeParenthesis) {
                unbalanced--;
            }
            if (unbalanced) {
                this.parse();
            }
        }
        
        this.current = cache;
    } else {
        // 不期望的括号
        this.unexpected();
    }
}
```

### 3.6 命名空间处理

CSS支持XML命名空间：

```css
ns|element     /* 命名空间元素 */
*|element      /* 任意命名空间 */
|element       /* 无命名空间 */
```

```javascript
namespace() {
    const before = this.prevToken && this.content(this.prevToken) || true;
    
    if (this.nextToken[TYPE] === tokens.word) {
        this.position++;
        return this.word(before);  // 传递命名空间
    } else if (this.nextToken[TYPE] === tokens.asterisk) {
        this.position++;
        return this.universal(before);  // 传递命名空间
    }
    
    this.unexpectedPipe();
}
```

### 3.7 空白字符处理

解析器支持两种模式：

1. **Lossless模式**（默认）：保留所有空白字符
2. **Lossy模式**：标准化空白字符

```javascript
parseWhitespaceEquivalentTokens(stopPosition) {
    let nodes = [];
    let space = "";
    
    do {
        if (WHITESPACE_TOKENS[this.currToken[TYPE]]) {
            if (!this.options.lossy) {
                space += this.content();
            }
        } else if (this.currToken[TYPE] === tokens.comment) {
            let spaces = {};
            if (space) {
                spaces.before = space;
                space = "";
            }
            nodes.push(new Comment({
                value: this.content(),
                spaces: spaces
            }));
        }
    } while (++this.position < stopPosition);
    
    return nodes;
}
```

## 处理器（Processor）

### 4.1 Processor接口

Processor类提供了统一的API接口：

```javascript
class Processor {
    constructor(func, options) {
        this.func = func || function noop() {};
        this.options = options;
    }
    
    // 异步处理，返回Promise
    process(rule, options) {
        return this._run(rule, options)
            .then(result => result.string || result.root.toString());
    }
    
    // 同步处理
    processSync(rule, options) {
        let result = this._runSync(rule, options);
        return result.string || result.root.toString();
    }
    
    // 获取AST
    ast(rule, options) {
        return this._run(rule, options).then(result => result.root);
    }
    
    astSync(rule, options) {
        return this._runSync(rule, options).root;
    }
}
```

### 4.2 使用示例

```javascript
const parser = require('postcss-selector-parser');

// 基本使用
const transform = selectors => {
    selectors.walk(selector => {
        console.log(String(selector));
    });
};

const result = parser(transform).processSync('h1, h2, h3');

// 获取AST
const ast = parser().astSync('div.class#id');
// Root {
//   nodes: [
//     Selector {
//       nodes: [
//         Tag { value: 'div' },
//         ClassName { value: 'class' },
//         ID { value: 'id' }
//       ]
//     }
//   ]
// }

// 修改选择器
const addPrefix = parser(selectors => {
    selectors.walkClasses(classNode => {
        classNode.value = 'prefix-' + classNode.value;
    });
});

addPrefix.processSync('.button');  // => .prefix-button
```

## 完整解析示例

让我们通过一个完整的例子来理解整个解析过程：

### 输入：`div.class > span:hover`

#### 第一步：词法分析

```javascript
tokens = [
    [word, 1, 0, 1, 2, 0, 3],           // "div"
    [word, 1, 3, 1, 7, 3, 8],           // ".class"
    [space, 1, 8, 1, 8, 8, 9],          // " "
    [greaterThan, 1, 9, 1, 9, 9, 10],   // ">"
    [space, 1, 10, 1, 10, 10, 11],      // " "
    [word, 1, 11, 1, 14, 11, 15],       // "span"
    [colon, 1, 15, 1, 15, 15, 16],      // ":"
    [word, 1, 16, 1, 20, 16, 21]        // "hover"
]
```

#### 第二步：语法分析

```javascript
// 1. 创建Root节点
Root {
    nodes: [
        Selector {
            nodes: []
        }
    ]
}

// 2. 解析 "div" (word token)
//    splitWord识别为标签
Root {
    nodes: [
        Selector {
            nodes: [
                Tag { value: 'div' }
            ]
        }
    ]
}

// 3. 解析 ".class" (word token)
//    splitWord识别点号，分割为类选择器
Root {
    nodes: [
        Selector {
            nodes: [
                Tag { value: 'div' },
                ClassName { value: 'class' }
            ]
        }
    ]
}

// 4. 解析 " > " (space + greaterThan + space)
//    combinator识别为子元素组合器
Root {
    nodes: [
        Selector {
            nodes: [
                Tag { value: 'div' },
                ClassName { value: 'class' },
                Combinator { value: '>', spaces: { before: ' ', after: ' ' } }
            ]
        }
    ]
}

// 5. 解析 "span" (word token)
Root {
    nodes: [
        Selector {
            nodes: [
                Tag { value: 'div' },
                ClassName { value: 'class' },
                Combinator { value: '>' },
                Tag { value: 'span' }
            ]
        }
    ]
}

// 6. 解析 ":hover" (colon + word)
//    pseudo识别为伪类
Root {
    nodes: [
        Selector {
            nodes: [
                Tag { value: 'div' },
                ClassName { value: 'class' },
                Combinator { value: '>' },
                Tag { value: 'span' },
                Pseudo { value: ':hover' }
            ]
        }
    ]
}
```

#### 第三步：AST遍历

```javascript
// 遍历所有节点
ast.walk(node => {
    console.log(node.type, node.value);
});
// 输出：
// root undefined
// selector undefined
// tag div
// class class
// combinator >
// tag span
// pseudo :hover

// 只遍历标签
ast.walkTags(tag => {
    console.log(tag.value);
});
// 输出：
// div
// span
```

## 高级特性

### 6.1 源码位置追踪

每个节点都包含source信息，用于错误报告：

```javascript
node.source = {
    start: { line: 1, column: 0 },
    end: { line: 1, column: 3 }
};
node.sourceIndex = 0;  // 在原始字符串中的索引
```

### 6.2 原始值保存

为了保证往返转换的准确性，解析器保存原始值：

```javascript
node.value = 'class';           // 转义后的值
node.raws.value = 'cl\\61ss';   // 原始值（包含转义）
```

### 6.3 空白字符处理

解析器精确跟踪空白字符：

```javascript
node.spaces = {
    before: ' ',   // 节点前的空白
    after: '  '    // 节点后的空白
};

// 在lossy模式下，空白被标准化
```

### 6.4 错误处理

解析器提供详细的错误信息：

```javascript
try {
    parser().processSync('[attr');
} catch (error) {
    console.log(error.message);
    // "Expected a closing square bracket."
    console.log(error.line);    // 1
    console.log(error.column);  // 5
}
```

## 总结

postcss-selector-parser的实现展示了经典的编译器前端设计：

1. **词法分析**：将字符流转换为token流
   - 状态机驱动
   - 处理转义序列
   - 跟踪位置信息

2. **语法分析**：将token流转换为AST
   - 递归下降解析
   - 状态机处理复杂语法
   - 保留源码信息

3. **AST操作**：提供丰富的API
   - 遍历节点
   - 修改节点
   - 生成代码

这种设计使得CSS选择器的解析、分析和转换变得简单而可靠。
