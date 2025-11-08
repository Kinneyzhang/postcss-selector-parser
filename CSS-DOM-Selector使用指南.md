# CSS DOM Selector - CSS选择器DOM查询与样式应用

这是一个Emacs Lisp库，它结合了`css-selector-parser.el`的CSS选择器解析功能和Emacs的`dom.el`库，实现了类似浏览器中`querySelector`和`querySelectorAll`的功能。

## 功能特性

### 🔍 DOM查询
- **querySelector** - 查询第一个匹配的节点
- **querySelectorAll** - 查询所有匹配的节点
- 支持所有常见的CSS选择器语法

### 🎨 样式操作
- 为匹配的节点应用CSS样式
- 读取和修改节点的style属性
- 支持多个CSS属性的批量设置

### 📦 类操作
- 添加、删除、检查、切换CSS类
- 类名空格分隔处理
- 方便的类操作API

## 安装

1. 确保已经加载了依赖库：
```elisp
(require 'dom)
(require 'css-selector-parser)
```

2. 加载CSS DOM选择器库：
```elisp
(load-file "path/to/css-dom-selector.el")
```

## 支持的选择器

### 基础选择器
- **标签选择器**: `div`, `p`, `span`
- **类选择器**: `.class`, `.multiple.classes`
- **ID选择器**: `#id`
- **通配符**: `*`
- **属性选择器**: `[attr]`, `[attr="value"]`, `[attr^="prefix"]`

### 组合选择器
- **后代选择器**: `div p` (空格)
- **子选择器**: `div > p` (>)
- **相邻兄弟**: `div + p` (+)
- **通用兄弟**: `div ~ p` (~)

### 复合选择器
- **多个类**: `.class1.class2`
- **标签+类**: `div.class`
- **标签+ID**: `div#id`
- **组合**: `div.class#id[attr]`

### 属性选择器操作符
- `[attr]` - 属性存在
- `[attr="value"]` - 完全匹配
- `[attr^="value"]` - 前缀匹配
- `[attr$="value"]` - 后缀匹配
- `[attr*="value"]` - 包含匹配
- `[attr~="value"]` - 单词匹配
- `[attr|="value"]` - 连字符匹配

### 伪类（基础支持）
- `:first-child`
- `:last-child`
- `:only-child`

## API文档

### DOM查询函数

#### `css-dom-query-selector`
```elisp
(css-dom-query-selector dom selector-string)
```
在DOM树中查询第一个匹配CSS选择器的节点。

**参数:**
- `dom` - DOM树根节点
- `selector-string` - CSS选择器字符串

**返回:** 第一个匹配的节点，如果没有则返回nil

**示例:**
```elisp
(css-dom-query-selector dom "#header")
;; => (div ((id . "header")) ...)

(css-dom-query-selector dom ".button")
;; => (button ((class . "button")) "Click me")
```

#### `css-dom-query-selector-all`
```elisp
(css-dom-query-selector-all dom selector-string)
```
在DOM树中查询所有匹配CSS选择器的节点。

**参数:**
- `dom` - DOM树根节点
- `selector-string` - CSS选择器字符串

**返回:** 匹配节点的列表

**示例:**
```elisp
(css-dom-query-selector-all dom "p.text")
;; => ((p ((class . "text")) "First") (p ((class . "text")) "Second"))

(css-dom-query-selector-all dom "nav a")
;; => ((a ((href . "/")) "Home") (a ((href . "/about")) "About"))
```

### 样式操作函数

#### `css-dom-apply-style`
```elisp
(css-dom-apply-style dom selector-string styles)
```
为DOM中匹配选择器的节点应用CSS样式。

**参数:**
- `dom` - DOM树根节点
- `selector-string` - CSS选择器字符串
- `styles` - 样式列表，格式为 `((property . value) ...)`

**返回:** 受影响的节点列表

**示例:**
```elisp
(css-dom-apply-style dom ".button"
  '((color . "white")
    (background-color . "blue")
    (padding . "10px 20px")
    (border-radius . "4px")))
```

#### `css-dom-set-styles`
```elisp
(css-dom-set-styles node styles)
```
为单个DOM节点设置CSS样式。

**参数:**
- `node` - DOM节点
- `styles` - 样式列表

**示例:**
```elisp
(css-dom-set-styles node
  '((color . "red")
    (font-size . "16px")))
```

#### `css-dom-get-style`
```elisp
(css-dom-get-style node property)
```
获取DOM节点的指定CSS属性值。

**参数:**
- `node` - DOM节点
- `property` - CSS属性名（symbol）

**返回:** 属性值字符串，如果不存在则返回nil

**示例:**
```elisp
(css-dom-get-style node 'color)
;; => "red"

(css-dom-get-style node 'font-size)
;; => "16px"
```

### 类操作函数

#### `css-dom-add-class`
```elisp
(css-dom-add-class node class-name)
```
为DOM节点添加CSS类。

**示例:**
```elisp
(css-dom-add-class node "active")
(css-dom-add-class node "highlighted")
```

#### `css-dom-remove-class`
```elisp
(css-dom-remove-class node class-name)
```
从DOM节点移除CSS类。

**示例:**
```elisp
(css-dom-remove-class node "hidden")
```

#### `css-dom-has-class`
```elisp
(css-dom-has-class node class-name)
```
检查DOM节点是否有指定的CSS类。

**返回:** 如果有该类则返回t，否则返回nil

**示例:**
```elisp
(css-dom-has-class node "active")
;; => t

(css-dom-has-class node "hidden")
;; => nil
```

#### `css-dom-toggle-class`
```elisp
(css-dom-toggle-class node class-name)
```
切换DOM节点的CSS类（如果有则删除，没有则添加）。

**示例:**
```elisp
(css-dom-toggle-class node "expanded")
```

## 使用示例

### 示例1：基础查询

```elisp
;; 创建示例DOM
(setq my-dom
  '(html nil
    (body nil
      (div ((id . "header") (class . "header fixed"))
        (h1 nil "My Site")
        (nav ((class . "menu"))
          (ul nil
            (li ((class . "item")) (a ((href . "/")) "Home"))
            (li ((class . "item active")) (a ((href . "/about")) "About"))))))))

;; 按ID查询
(css-dom-query-selector my-dom "#header")
;; => (div ((id . "header") (class . "header fixed")) ...)

;; 按类查询所有
(css-dom-query-selector-all my-dom ".item")
;; => ((li ((class . "item")) ...) (li ((class . "item active")) ...))

;; 查询链接
(css-dom-query-selector-all my-dom "nav a")
;; => ((a ((href . "/")) "Home") (a ((href . "/about")) "About"))
```

### 示例2：样式应用

```elisp
;; 为所有链接设置样式
(css-dom-apply-style my-dom "a"
  '((color . "blue")
    (text-decoration . "none")))

;; 为激活的菜单项设置样式
(css-dom-apply-style my-dom ".item.active"
  '((font-weight . "bold")
    (border-bottom . "2px solid #333")))

;; 为标题设置样式
(let ((header (css-dom-query-selector my-dom "#header")))
  (css-dom-set-styles header
    '((background-color . "#333")
      (color . "white")
      (padding . "20px"))))
```

### 示例3：类操作

```elisp
;; 获取导航节点
(setq nav (css-dom-query-selector my-dom "nav"))

;; 添加类
(css-dom-add-class nav "mobile-menu")

;; 检查类
(css-dom-has-class nav "menu")  ;; => t
(css-dom-has-class nav "hidden") ;; => nil

;; 切换类
(css-dom-toggle-class nav "collapsed")

;; 移除类
(css-dom-remove-class nav "mobile-menu")
```

### 示例4：实用工具

```elisp
;; 提取所有链接
(defun extract-all-links (dom)
  "提取DOM中的所有链接。"
  (mapcar (lambda (link)
            (cons (car (dom-strings link))
                  (cdr (assq 'href (dom-attributes link)))))
          (css-dom-query-selector-all dom "a")))

(extract-all-links my-dom)
;; => (("Home" . "/") ("About" . "/about"))

;; 高亮所有外部链接
(defun highlight-external-links (dom)
  "为外部链接添加样式。"
  (let ((links (css-dom-query-selector-all dom "a[href]")))
    (dolist (link links)
      (let ((href (cdr (assq 'href (dom-attributes link)))))
        (when (string-match-p "^http" href)
          (css-dom-set-styles link
            '((color . "blue")
              (text-decoration . "underline"))))))))
```

### 示例5：主题切换

```elisp
(defun apply-dark-theme (dom)
  "应用深色主题到DOM。"
  ;; 背景和文本颜色
  (css-dom-apply-style dom "body"
    '((background-color . "#1a1a1a")
      (color . "#ffffff")))
  
  ;; 头部样式
  (css-dom-apply-style dom "#header"
    '((background-color . "#2d2d2d")
      (border-bottom . "1px solid #444")))
  
  ;; 链接样式
  (css-dom-apply-style dom "a"
    '((color . "#6cb6ff")))
  
  ;; 激活项
  (css-dom-apply-style dom ".active"
    '((color . "#ffd700"))))

(apply-dark-theme my-dom)
```

## DOM结构

Emacs的`dom.el`使用以下结构表示DOM节点：

```elisp
(tag-name ((attr1 . "value1") (attr2 . "value2")) child1 child2 ...)
```

**示例:**
```elisp
(div ((id . "container") (class . "main"))
  (h1 nil "Title")
  (p ((class . "text")) "Content"))
```

**节点组成:**
- 第一个元素：标签名（symbol）
- 第二个元素：属性列表（alist）
- 其余元素：子节点

## 运行示例

加载并运行示例代码：

```elisp
;; 加载示例
(load-file "css-dom-selector-examples.el")

;; 运行所有示例
(css-dom-selector-run-examples)

;; 或运行内置示例
(css-dom-selector-examples)
```

## 性能说明

当前实现主要关注功能完整性和代码可读性，适合教学和中小规模DOM树的操作。对于大型DOM树或性能敏感的应用，可以考虑以下优化：

- 缓存解析后的选择器AST
- 实现索引加速ID和类查询
- 优化遍历算法
- 使用哈希表加速属性查找

## 限制和未来改进

### 当前限制
1. 伪类支持有限（仅支持基本结构伪类）
2. 组合器的完整性实现需要增强
3. 不支持伪元素
4. 不支持`:nth-child()`等带参数的伪类

### 未来改进方向
- 完整的伪类支持
- 性能优化
- 更好的错误处理
- CSS3选择器完整支持
- 选择器性能分析工具

## 与JavaScript DOM API对比

| JavaScript | Emacs Lisp | 说明 |
|-----------|-----------|------|
| `document.querySelector(sel)` | `(css-dom-query-selector dom sel)` | 查询单个节点 |
| `document.querySelectorAll(sel)` | `(css-dom-query-selector-all dom sel)` | 查询所有节点 |
| `element.style.color = "red"` | `(css-dom-set-styles node '((color . "red")))` | 设置样式 |
| `element.classList.add("class")` | `(css-dom-add-class node "class")` | 添加类 |
| `element.classList.remove("class")` | `(css-dom-remove-class node "class")` | 移除类 |
| `element.classList.contains("class")` | `(css-dom-has-class node "class")` | 检查类 |
| `element.classList.toggle("class")` | `(css-dom-toggle-class node "class")` | 切换类 |

## 实际应用场景

1. **网页抓取和解析** - 从HTML中提取特定信息
2. **文档转换** - 将HTML转换为其他格式
3. **样式注入** - 为HTML添加或修改样式
4. **内容过滤** - 基于选择器过滤内容
5. **测试工具** - DOM操作测试
6. **邮件HTML处理** - 在Emacs中处理HTML邮件
7. **Web开发辅助** - DOM结构分析和调试

## 相关项目

- [css-selector-parser.el](./css-selector-parser.el) - CSS选择器解析器
- [examples.el](./examples.el) - 解析器使用示例
- [dom.el](https://www.gnu.org/software/emacs/manual/html_node/elisp/Document-Object-Model.html) - Emacs内置DOM库

## 许可证

本项目遵循MIT许可证。

## 贡献

欢迎提交问题报告和改进建议！

---

**愿这个库能让你在Emacs中轻松操作DOM！** 🎉
