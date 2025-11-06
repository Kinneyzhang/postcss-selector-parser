# CSS选择器解析器使用指南

## 项目简介

本项目提供了两个主要文档：

1. **CSS选择器解析器实现详解.md** - 详细的中文技术文档，解释postcss-selector-parser的实现原理
2. **css-selector-parser.el** - 使用Emacs Lisp重新实现的CSS选择器解析器

## 文档说明

### CSS选择器解析器实现详解.md

这个文档深入讲解了postcss-selector-parser的实现机制，包括：

#### 1. 整体架构
- 词法分析（Tokenization）
- 语法分析（Parsing）  
- AST构建和操作

#### 2. 词法分析器详解
- Token类型定义
- Token结构说明
- 转义序列处理
- 单词识别算法
- 字符串和注释处理

#### 3. 语法分析器详解
- AST节点类型系统
- 解析器主循环
- 各种选择器的解析方法：
  - 标签选择器
  - 类选择器
  - ID选择器
  - 属性选择器
  - 伪类和伪元素
  - 组合器
  - 命名空间

#### 4. 完整解析示例
通过一个完整的例子展示从CSS字符串到AST的全过程

## Emacs Lisp实现

### 功能特性

`css-selector-parser.el` 提供了完整的CSS选择器解析功能：

- ✅ 完整的词法分析器
- ✅ 语法分析器
- ✅ AST构建
- ✅ 节点遍历
- ✅ AST序列化
- ✅ 支持所有主要CSS选择器类型

### 支持的选择器

- 标签选择器: `div`, `span`, `h1`
- 类选择器: `.class`, `.my-class`
- ID选择器: `#id`, `#my-id`
- 通配符: `*`
- 属性选择器: `[attr]`, `[attr="value"]`, `[attr^="prefix"]`
- 伪类: `:hover`, `:first-child`
- 伪元素: `::before`, `::after`
- 组合器: ` ` (后代), `>` (子元素), `+` (相邻), `~` (兄弟)
- 多个选择器: `div, span`
- 嵌套选择器: `&`

### 安装使用

#### 1. 加载库

```elisp
(load-file "/path/to/css-selector-parser.el")
```

或者将文件放在Emacs的load-path中：

```elisp
(require 'css-selector-parser)
```

#### 2. 基本使用

##### 解析选择器

```elisp
;; 解析简单选择器
(setq ast (css-selector-parse "div.class#id"))

;; 结果是一个plist结构的AST树
;; (:type root 
;;  :nodes ((:type selector 
;;           :nodes ((:type tag :value "div" :spaces (:before "" :after ""))
;;                   (:type class :value "class" :spaces (:before "" :after ""))
;;                   (:type id :value "id" :spaces (:before "" :after ""))))))
```

##### 遍历AST

```elisp
;; 遍历所有节点
(css-selector-walk ast
  (lambda (node)
    (message "节点类型: %s" (plist-get node :type))))

;; 只遍历类选择器
(css-selector-walk-classes ast
  (lambda (node)
    (message "类名: %s" (plist-get node :value))))

;; 只遍历标签选择器
(css-selector-walk-tags ast
  (lambda (node)
    (message "标签: %s" (plist-get node :value))))
```

##### AST转字符串

```elisp
;; 将AST转回CSS字符串
(css-selector-stringify ast)
;; => "div.class#id"
```

### 详细示例

#### 示例1：解析复杂选择器

```elisp
(setq ast (css-selector-parse "div.container > p.text + span:hover"))

;; 遍历所有节点查看结构
(css-selector-walk ast
  (lambda (node)
    (let ((type (plist-get node :type))
          (value (plist-get node :value)))
      (message "类型: %s, 值: %s" type value))))

;; 输出：
;; 类型: root, 值: nil
;; 类型: selector, 值: nil
;; 类型: tag, 值: div
;; 类型: class, 值: container
;; 类型: combinator, 值: >
;; 类型: tag, 值: p
;; 类型: class, 值: text
;; 类型: combinator, 值: +
;; 类型: tag, 值: span
;; 类型: pseudo, 值: :hover
```

#### 示例2：提取所有类名

```elisp
(defun extract-class-names (selector)
  "从CSS选择器中提取所有类名。"
  (let ((ast (css-selector-parse selector))
        (classes '()))
    (css-selector-walk-classes ast
      (lambda (node)
        (push (plist-get node :value) classes)))
    (nreverse classes)))

(extract-class-names "div.container > p.text.large + span.icon")
;; => ("container" "text" "large" "icon")
```

#### 示例3：修改类名前缀

```elisp
(defun add-class-prefix (selector prefix)
  "为选择器中的所有类添加前缀。"
  (let ((ast (css-selector-parse selector)))
    (css-selector-walk-classes ast
      (lambda (node)
        (let ((old-value (plist-get node :value)))
          (plist-put node :value (concat prefix old-value)))))
    (css-selector-stringify ast)))

(add-class-prefix ".button.large" "my-")
;; => ".my-button.my-large"
```

#### 示例4：检查选择器特性

```elisp
(defun selector-has-pseudo-class-p (selector)
  "检查选择器是否包含伪类。"
  (let ((ast (css-selector-parse selector))
        (has-pseudo nil))
    (css-selector-walk-pseudos ast
      (lambda (node)
        (setq has-pseudo t)))
    has-pseudo))

(selector-has-pseudo-class-p "a:hover")     ;; => t
(selector-has-pseudo-class-p "div.class")   ;; => nil
```

#### 示例5：分析选择器复杂度

```elisp
(defun analyze-selector (selector)
  "分析选择器的组成部分。"
  (let ((ast (css-selector-parse selector))
        (stats (list :tags 0 :classes 0 :ids 0 :pseudos 0 :attributes 0)))
    (css-selector-walk ast
      (lambda (node)
        (let ((type (plist-get node :type)))
          (cond
           ((eq type 'tag)
            (cl-incf (plist-get stats :tags)))
           ((eq type 'class)
            (cl-incf (plist-get stats :classes)))
           ((eq type 'id)
            (cl-incf (plist-get stats :ids)))
           ((eq type 'pseudo)
            (cl-incf (plist-get stats :pseudos)))
           ((eq type 'attribute)
            (cl-incf (plist-get stats :attributes)))))))
    stats))

(analyze-selector "div.container#main > p.text:first-child[lang='en']")
;; => (:tags 2 :classes 2 :ids 1 :pseudos 1 :attributes 1)
```

### API参考

#### 解析函数

##### `css-selector-parse`

```elisp
(css-selector-parse selector-string)
```

解析CSS选择器字符串，返回AST树结构。

**参数:**
- `selector-string`: 要解析的CSS选择器字符串

**返回值:**
- AST树（plist结构）

**示例:**
```elisp
(css-selector-parse "div.class")
```

#### 遍历函数

##### `css-selector-walk`

```elisp
(css-selector-walk ast func)
```

遍历AST的所有节点，对每个节点调用func。

**参数:**
- `ast`: AST树
- `func`: 对每个节点调用的函数，接收节点作为参数

**示例:**
```elisp
(css-selector-walk ast
  (lambda (node)
    (message "Node: %S" node)))
```

##### `css-selector-walk-type`

```elisp
(css-selector-walk-type ast node-type func)
```

遍历AST中指定类型的节点。

**参数:**
- `ast`: AST树
- `node-type`: 节点类型符号（如 `'class`, `'tag`）
- `func`: 对匹配节点调用的函数

##### 便捷遍历函数

- `css-selector-walk-tags` - 遍历所有标签选择器
- `css-selector-walk-classes` - 遍历所有类选择器
- `css-selector-walk-ids` - 遍历所有ID选择器
- `css-selector-walk-pseudos` - 遍历所有伪类/伪元素
- `css-selector-walk-attributes` - 遍历所有属性选择器

#### 序列化函数

##### `css-selector-stringify`

```elisp
(css-selector-stringify ast)
```

将AST转换回CSS选择器字符串。

**参数:**
- `ast`: AST树

**返回值:**
- CSS选择器字符串

**示例:**
```elisp
(css-selector-stringify (css-selector-parse "div.class"))
;; => "div.class"
```

### AST节点结构

所有节点都是plist结构，包含以下基本属性：

```elisp
(:type 'node-type           ; 节点类型符号
 :value "value"              ; 节点值（如果适用）
 :spaces (:before "" :after "")  ; 空白字符
 :nodes (...)                ; 子节点列表（容器节点）
 ...)                        ; 其他特定属性
```

#### 节点类型

- **root**: 根节点，包含所有选择器
  - `:nodes` - 选择器列表

- **selector**: 选择器节点
  - `:nodes` - 选择器组成部分列表

- **tag**: 标签选择器
  - `:value` - 标签名

- **class**: 类选择器
  - `:value` - 类名（不含点号）

- **id**: ID选择器
  - `:value` - ID值（不含井号）

- **universal**: 通配符选择器
  - `:value` - 固定为 "*"

- **attribute**: 属性选择器
  - `:attribute` - 属性名
  - `:operator` - 操作符（可选）
  - `:value` - 属性值（可选）
  - `:quote-mark` - 引号类型（可选）

- **pseudo**: 伪类/伪元素
  - `:value` - 伪类名（含冒号）

- **combinator**: 组合器
  - `:value` - 组合器字符

- **nesting**: 嵌套选择器
  - `:value` - 固定为 "&"

- **comment**: 注释
  - `:value` - 注释内容

### 运行示例

在Emacs中运行：

```elisp
;; 加载库
(load-file "css-selector-parser.el")

;; 运行示例函数
(css-selector-parser-examples)
```

这会打开一个缓冲区显示各种使用示例。

### 实现说明

#### 词法分析

词法分析器 (`css-tokenize`) 实现了完整的CSS选择器词法分析：

1. **字符识别**: 识别各种CSS字符（操作符、分隔符等）
2. **转义处理**: 支持反斜杠转义和十六进制转义
3. **字符串解析**: 正确处理引号字符串
4. **注释处理**: 识别CSS注释 `/* ... */`
5. **位置跟踪**: 记录每个token的行号、列号和位置

#### 语法分析

语法分析器 (`css-parser-*` 函数) 实现了递归下降解析：

1. **主循环**: 遍历所有token并分派到相应的处理函数
2. **节点构建**: 为每种选择器类型创建相应的AST节点
3. **复杂选择器**: 支持组合选择器和嵌套结构
4. **错误处理**: 提供基本的语法错误检测

#### 限制

当前实现是简化版本，有以下限制：

1. 属性选择器不支持所有操作符组合
2. 伪类不支持带参数的形式（如 `:nth-child(2n+1)`）
3. 错误处理较为简单
4. 不支持CSS4的一些新特性

这些限制可以通过扩展代码来解决。

## 与原始实现的对比

### 相似之处

1. **架构设计**: 都采用词法分析→语法分析→AST的经典编译器架构
2. **Token结构**: Token包含相同的信息（类型、位置、值）
3. **AST节点**: 节点类型和结构基本一致
4. **遍历API**: 提供类似的遍历和操作接口

### 差异之处

1. **语言特性**:
   - JavaScript实现使用类和原型
   - Emacs Lisp使用结构体和plist

2. **数据结构**:
   - JavaScript使用对象和数组
   - Emacs Lisp使用plist和列表

3. **功能完整性**:
   - JavaScript版本功能更完整
   - Emacs Lisp版本是简化的核心实现

4. **性能考虑**:
   - JavaScript针对性能优化
   - Emacs Lisp注重可读性和简洁性

## 学习建议

1. **先读文档**: 阅读"CSS选择器解析器实现详解.md"理解原理
2. **对照代码**: 对比JavaScript原始实现和Emacs Lisp实现
3. **运行示例**: 在Emacs中运行示例函数理解用法
4. **扩展功能**: 尝试添加新功能（如更多属性选择器支持）
5. **测试用例**: 编写测试用例验证解析正确性

## 应用场景

### 在Emacs中的应用

1. **CSS编辑辅助**: 分析和重构CSS选择器
2. **代码检查**: 检查选择器复杂度和规范
3. **自动补全**: 基于已有选择器提供补全
4. **重命名工具**: 批量重命名类名或ID
5. **选择器优化**: 简化过于复杂的选择器

### 示例工具函数

```elisp
(defun my/rename-css-class (old-class new-class)
  "在当前缓冲区中重命名CSS类。"
  (interactive "sOld class name: \nsNew class name: ")
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "\\([.#]\\|\\w\\)\\([a-zA-Z0-9_-]+\\)" nil t)
      (let* ((selector (match-string 0))
             (ast (css-selector-parse selector)))
        (css-selector-walk-classes ast
          (lambda (node)
            (when (string= (plist-get node :value) old-class)
              (plist-put node :value new-class))))
        (replace-match (css-selector-stringify ast))))))
```

## 贡献和改进

欢迎对实现进行改进：

1. 添加更完整的属性选择器支持
2. 实现带参数的伪类解析
3. 改进错误处理和报告
4. 添加更多便捷函数
5. 优化性能
6. 增加测试用例

## 参考资源

- [postcss-selector-parser GitHub](https://github.com/postcss/postcss-selector-parser)
- [CSS Selectors Level 4](https://www.w3.org/TR/selectors-4/)
- [编译原理基础](https://en.wikipedia.org/wiki/Compiler)

## 许可证

本实现基于postcss-selector-parser项目，遵循MIT许可证。

## 总结

通过这个项目，你可以：

1. 深入理解CSS选择器的解析原理
2. 学习编译器前端的基本概念（词法分析、语法分析）
3. 掌握AST的构建和操作技术
4. 在Emacs中使用Lisp处理CSS选择器
5. 为CSS工具开发打下基础

希望这些文档和代码能帮助你更好地理解CSS选择器解析的实现！
