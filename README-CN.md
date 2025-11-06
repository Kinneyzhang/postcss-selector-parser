# CSS选择器解析器 - 中文文档与Emacs Lisp实现

本项目为postcss-selector-parser提供了详细的中文技术文档和完整的Emacs Lisp重新实现。

## 📚 项目内容

### 1. 技术文档

#### [CSS选择器解析器实现详解.md](./CSS选择器解析器实现详解.md)

这是一份详尽的中文技术文档，深入解析postcss-selector-parser的实现原理，包括：

- **整体架构**
  - 词法分析 → 语法分析 → AST的完整流程
  - 模块组织和设计模式

- **词法分析器（Tokenizer）详解**
  - Token类型定义和结构
  - 字符识别和分类
  - 转义序列处理（十六进制和字符转义）
  - 单词、字符串、注释的解析算法
  - 位置跟踪机制

- **语法分析器（Parser）详解**
  - AST节点类型系统
  - 递归下降解析算法
  - 各种选择器的解析方法：
    - 标签选择器、类选择器、ID选择器
    - 属性选择器的状态机解析
    - 伪类和伪元素处理
    - 组合器识别（后代、子元素、相邻、兄弟）
    - 命名空间处理
  - 空白字符的精确处理

- **完整解析示例**
  - 从`div.class > span:hover`到AST的完整过程
  - 每一步的详细说明和中间结果

### 2. Emacs Lisp实现

#### [css-selector-parser.el](./css-selector-parser.el)

使用Emacs Lisp完全重新实现的CSS选择器解析器，特点：

- ✅ **完整的词法分析器** - 支持所有CSS选择器字符
- ✅ **功能完备的语法分析器** - 构建标准的AST
- ✅ **丰富的API** - 解析、遍历、修改、序列化
- ✅ **清晰的代码结构** - 易于理解和学习
- ✅ **详细的注释** - 每个函数都有说明文档

**主要功能：**

```elisp
;; 解析CSS选择器
(css-selector-parse "div.class#id > span:hover")

;; 遍历AST节点
(css-selector-walk ast func)

;; 类型化遍历
(css-selector-walk-classes ast func)
(css-selector-walk-tags ast func)
(css-selector-walk-pseudos ast func)

;; 序列化为字符串
(css-selector-stringify ast)
```

#### [examples.el](./examples.el)

15个实用示例，展示各种使用场景：

1. 基本选择器解析
2. 复杂选择器处理
3. 伪类和伪元素
4. 属性选择器
5. AST遍历技巧
6. 提取类名工具
7. 选择器统计分析
8. 类名前缀添加
9. 选择器特异性计算
10. 伪类检测
11. 标签提取
12. 复杂度评估
13. 选择器规范化
14. 列表表示转换
15. 选择器相似度比较

### 3. 使用指南

#### [CSS解析器使用指南.md](./CSS解析器使用指南.md)

完整的使用手册，包括：

- 安装和配置说明
- 详细的API文档
- 实用示例代码
- 最佳实践
- 应用场景
- 扩展建议

#### [test-implementation.md](./test-implementation.md)

测试说明文档：

- 测试环境设置
- 测试方法说明
- 预期结果示例
- 已知限制
- 验证工具

## 🚀 快速开始

### 查看文档

直接阅读`CSS选择器解析器实现详解.md`了解实现原理。

### 使用Emacs Lisp实现

1. 在Emacs中加载库：

```elisp
(load-file "path/to/css-selector-parser.el")
```

2. 解析选择器：

```elisp
;; 解析
(setq ast (css-selector-parse "div.button:hover"))

;; 遍历
(css-selector-walk-classes ast
  (lambda (node)
    (message "Class: %s" (plist-get node :value))))

;; 序列化
(css-selector-stringify ast)
```

3. 运行示例：

```elisp
(load-file "examples.el")
(css-selector-parser-run-examples)
```

## 📖 支持的CSS选择器

| 类型 | 示例 | 支持 |
|------|------|------|
| 标签选择器 | `div`, `span` | ✅ |
| 类选择器 | `.class` | ✅ |
| ID选择器 | `#id` | ✅ |
| 通配符 | `*` | ✅ |
| 属性选择器 | `[attr]`, `[attr="value"]` | ✅ (基本) |
| 伪类 | `:hover`, `:first-child` | ✅ |
| 伪元素 | `::before`, `::after` | ✅ |
| 后代选择器 | `div span` | ✅ |
| 子选择器 | `div > span` | ✅ |
| 相邻兄弟 | `div + span` | ✅ |
| 通用兄弟 | `div ~ span` | ✅ |
| 组合选择器 | `div, span` | ✅ |
| 嵌套选择器 | `&` | ✅ |
| 注释 | `/* comment */` | ✅ |

## 💡 实际应用示例

### 示例1：提取所有类名

```elisp
(defun extract-classes (selector)
  "从选择器中提取所有类名。"
  (let ((ast (css-selector-parse selector))
        (classes '()))
    (css-selector-walk-classes ast
      (lambda (node)
        (push (plist-get node :value) classes)))
    (nreverse classes)))

(extract-classes "div.header.fixed > nav.menu ul.items")
;; => ("header" "fixed" "menu" "items")
```

### 示例2：为类名添加前缀

```elisp
(defun add-prefix (selector prefix)
  "为所有类添加前缀。"
  (let ((ast (css-selector-parse selector)))
    (css-selector-walk-classes ast
      (lambda (node)
        (plist-put node :value 
                   (concat prefix (plist-get node :value)))))
    (css-selector-stringify ast)))

(add-prefix ".button.large" "my-")
;; => ".my-button.my-large"
```

### 示例3：计算选择器特异性

```elisp
(defun calculate-specificity (selector)
  "计算CSS选择器特异性 [IDs, Classes+Attrs+Pseudos, Elements]。"
  (let ((ast (css-selector-parse selector))
        (ids 0) (classes 0) (elements 0))
    (css-selector-walk ast
      (lambda (node)
        (let ((type (plist-get node :type)))
          (cond
           ((eq type 'id) (cl-incf ids))
           ((memq type '(class attribute pseudo)) (cl-incf classes))
           ((eq type 'tag) (cl-incf elements))))))
    (list ids classes elements)))

(calculate-specificity "div#main.container > p.text:hover")
;; => (1 3 2)
```

## 🎯 学习路径

1. **理解原理** - 阅读`CSS选择器解析器实现详解.md`
2. **查看实现** - 研究`css-selector-parser.el`的源代码
3. **运行示例** - 执行`examples.el`中的示例
4. **动手实践** - 基于API编写自己的工具
5. **扩展功能** - 添加新特性或优化性能

## 🔧 技术亮点

### 词法分析

- 基于状态机的token识别
- 完整的转义序列支持
- 精确的位置跟踪（行号、列号）

### 语法分析

- 递归下降解析算法
- 类型化的AST节点
- 保留所有源码信息（包括空白字符）

### API设计

- 函数式编程风格
- 易于使用的遍历接口
- 灵活的节点操作

## 📊 与原始实现对比

| 特性 | JavaScript版 | Emacs Lisp版 |
|------|-------------|--------------|
| 词法分析 | ✅ 完整 | ✅ 完整 |
| 语法分析 | ✅ 完整 | ✅ 核心功能 |
| 属性选择器 | ✅ 所有操作符 | ⚠️ 基本操作符 |
| 伪类参数 | ✅ 完整解析 | ❌ 不支持 |
| 命名空间 | ✅ 完整 | ⚠️ 简化 |
| 错误处理 | ✅ 详细 | ⚠️ 基本 |
| 性能优化 | ✅ 是 | ❌ 否（重点教学） |
| 代码可读性 | ✅ 好 | ✅ 极好 |

## 🤝 贡献指南

欢迎改进：

- 完善属性选择器支持
- 添加伪类参数解析
- 改进错误处理
- 性能优化
- 增加测试用例
- 改进文档

## 📝 许可证

本项目遵循MIT许可证。

## 🙏 致谢

- 感谢postcss-selector-parser项目提供优秀的实现
- 感谢PostCSS社区的支持

## 📞 联系方式

如有问题或建议，请提交issue或PR。

---

**希望这个项目能帮助你深入理解CSS选择器解析的原理和实现！** 🎉
