# CSS选择器解析器测试说明

## 测试环境要求

要测试Emacs Lisp实现，你需要：

1. 安装Emacs（24.3或更高版本）
2. 支持lexical-binding

## 运行测试

### 方法1：交互式测试

1. 启动Emacs
2. 加载解析器：
   ```elisp
   M-x load-file RET css-selector-parser.el RET
   ```
3. 运行示例：
   ```elisp
   M-x load-file RET examples.el RET
   M-x css-selector-parser-run-examples RET
   ```

### 方法2：命令行批处理测试

```bash
emacs --batch -l css-selector-parser.el -l examples.el -f run-all-examples
```

### 方法3：在REPL中测试

启动Emacs后，按 `M-x ielm` 进入Emacs Lisp REPL：

```elisp
;; 加载库
(load-file "css-selector-parser.el")

;; 测试基本解析
(css-selector-parse "div.class#id")

;; 测试字符串化
(css-selector-stringify (css-selector-parse "div.class"))

;; 测试遍历
(css-selector-walk 
 (css-selector-parse "div.class")
 (lambda (node) (message "Type: %s" (plist-get node :type))))
```

## 预期测试结果

### 测试1：简单选择器

```elisp
(css-selector-parse "div")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type tag :value "div" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试2：类选择器

```elisp
(css-selector-parse ".button")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type class :value "button" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试3：组合选择器

```elisp
(css-selector-parse "div.class#id")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type tag :value "div" :spaces (:before "" :after ""))
                  (:type class :value "class" :spaces (:before "" :after ""))
                  (:type id :value "id" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试4：后代选择器

```elisp
(css-selector-parse "div span")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type tag :value "div" :spaces (:before "" :after ""))
                  (:type combinator :value " " :spaces (:before "" :after ""))
                  (:type tag :value "span" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试5：子选择器

```elisp
(css-selector-parse "ul > li")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type tag :value "ul" :spaces (:before "" :after ""))
                  (:type combinator :value ">" :spaces (:before "" :after ""))
                  (:type tag :value "li" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试6：伪类

```elisp
(css-selector-parse "a:hover")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type tag :value "a" :spaces (:before "" :after ""))
                  (:type pseudo :value ":hover" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试7：属性选择器

```elisp
(css-selector-parse "[disabled]")
```

预期输出：
```elisp
(:type root 
 :nodes ((:type selector 
          :nodes ((:type attribute :attribute "disabled" :spaces (:before "" :after ""))))) 
 :spaces (:before "" :after ""))
```

### 测试8：字符串化

```elisp
(css-selector-stringify (css-selector-parse "div.class#id"))
```

预期输出：
```
"div.class#id"
```

### 测试9：遍历节点

```elisp
(let ((types '()))
  (css-selector-walk 
   (css-selector-parse "div.class > span")
   (lambda (node) (push (plist-get node :type) types)))
  (nreverse types))
```

预期输出：
```elisp
(root selector tag class combinator tag)
```

### 测试10：提取类名

```elisp
(let ((classes '()))
  (css-selector-walk-classes
   (css-selector-parse "div.header.fixed nav.menu")
   (lambda (node) (push (plist-get node :value) classes)))
  (nreverse classes))
```

预期输出：
```elisp
("header" "fixed" "menu")
```

## 已知限制

当前实现有以下限制：

1. **属性选择器**：不完全支持所有操作符组合
2. **伪类参数**：不支持带参数的伪类（如 `:nth-child(2n+1)`）
3. **括号内容**：不完全解析伪类函数的参数
4. **命名空间**：简化的命名空间处理
5. **错误处理**：基本的错误检测

## 性能考虑

这个实现是教学性质的，重点在于：
- 清晰的代码结构
- 易于理解的算法
- 完整的注释说明

对于生产环境，可能需要：
- 性能优化
- 更完善的错误处理
- 更多的边界情况处理

## 扩展建议

如果要扩展这个实现，可以考虑：

1. **完整的属性选择器支持**
   - 实现所有CSS3属性选择器操作符
   - 支持不区分大小写标志 `i`

2. **伪类参数解析**
   - `:nth-child()`, `:nth-of-type()` 等
   - `:not()`, `:is()`, `:where()` 等

3. **更好的错误处理**
   - 详细的错误消息
   - 错误位置跟踪
   - 错误恢复机制

4. **性能优化**
   - 使用更高效的数据结构
   - 减少不必要的内存分配
   - 优化字符串操作

5. **CSS4特性**
   - 支持CSS Selectors Level 4的新特性

## 验证工具

可以使用以下JavaScript代码验证解析结果的正确性：

```javascript
const parser = require('postcss-selector-parser');

function verify(selector) {
    const ast = parser().astSync(selector);
    console.log(JSON.stringify(ast, null, 2));
}

verify('div.class#id');
verify('ul > li + li');
verify('a:hover');
```

然后将结果与Emacs Lisp实现的输出进行对比。

## 总结

这个实现提供了CSS选择器解析的核心功能，是学习编译器原理和Emacs Lisp编程的良好示例。虽然存在一些限制，但对于理解CSS选择器的解析过程和AST的构建已经足够。
