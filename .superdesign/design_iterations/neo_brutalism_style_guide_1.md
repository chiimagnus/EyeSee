# EyeSee Neo-Brutalism Style Guide (Markdown)

## 1. 色彩 (Colors)

采用高对比度、鲜艳的色彩搭配，体现 Neo-Brutalism 的核心特征。

| 名称 | 变量 | 颜色值 (示例) | 说明 |
| :--- | :--- | :--- | :--- |
| **Background** | `--background` | `#FFFFFF` | 页面背景色 |
| **Foreground** | `--foreground` | `#000000` | 主要文字颜色 |
| **Primary** | `--primary` | `#C44` (橙色) | 主要操作按钮、重要信息 |
| **Primary Foreground** | `--primary-foreground` | `#FFFFFF` | 主要操作按钮上的文字 |
| **Secondary** | `--secondary` | `#7ED` (绿色) | 次要操作按钮、辅助信息 |
| **Secondary Foreground** | `--secondary-foreground` | `#000000` | 次要操作按钮上的文字 |
| **Accent** | `--accent` | `#45B7D1` (蓝色) | 强调色、链接颜色 |
| **Accent Foreground** | `--accent-foreground` | `#FFFFFF` | 强调色上的文字 |
| **Muted** | `--muted` | `#F0F0F0` | 背景色、分隔区域 |
| **Muted Foreground** | `--muted-foreground` | `#525252` | 次要文字颜色 |
| **Border** | `--border` | `#000000` | 边框颜色 |
| **Input** | `--input` | `#000000` | 输入框边框颜色 |

## 2. 字体 (Typography)

主要使用 **DM Sans** 作为无衬线字体，**Space Mono** 作为等宽字体。

```css
--font-sans: 'DM Sans', sans-serif;
--font-serif: ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;
--font-mono: 'Space Mono', monospace;
```

## 3. 组件 (Components)

### 按钮 (Buttons)

- **样式**: 粗黑边框 (`2px solid var(--border)`), 明显的偏移阴影 (`var(--shadow)`)。
- **交互**:
  - `:hover`: 产生轻微的位移效果，模拟“按压感”。
    ```css
    .button:hover {
      transform: translate(2px, 2px);
      box-shadow: 2px 2px 0px 0px hsl(0 0% 0% / 1.00);
    }
    ```
- **类型**:
  - `.button`: 默认按钮样式。
  - `.button-primary`: 使用 `--primary` 颜色。
  - `.button-secondary`: 使用 `--secondary` 颜色。

### 输入框 (Input Fields)

- **样式**: 粗黑边框 (`2px solid var(--border)`), 明显的偏移阴影 (`var(--shadow)`)。
- **背景**: `var(--background)`
- **文字**: `var(--foreground)`

### 卡片 (Cards)

- **样式**: 粗黑边框 (`2px solid var(--border)`), 明显的偏移阴影 (`var(--shadow)`)。
- **背景**: `var(--card)` (通常与 `--background` 相同或略有区别)
- **内边距**: `20px`

## 4. 阴影 (Shadows)

定义了一系列不同强度的偏移阴影，以创建深度感和“撕裂”效果。

```css
--shadow-2xs: 4px 4px 0px 0px hsl(0 0% 0% / 0.50);
--shadow-xs: 4px 4px 0px 0px hsl(0 0% 0% / 0.50);
--shadow-sm: 4px 4px 0px 0px hsl(0 0% 0% / 1.00), 4px 1px 2px -1px hsl(0 0% 0% / 1.00);
--shadow: 4px 4px 0px 0px hsl(0 0% 0% / 1.00), 4px 1px 2px -1px hsl(0 0% 0% / 1.00);
--shadow-md: 4px 4px 0px 0px hsl(0 0% 0% / 1.00), 4px 2px 4px -1px hsl(0 0% 0% / 1.00);
--shadow-lg: 4px 4px 0px 0px hsl(0 0% 0% / 1.00), 4px 4px 6px -1px hsl(0 0% 0% / 1.00);
--shadow-xl: 4px 4px 0px 0px hsl(0 0% 0% / 1.00), 4px 8px 10px -1px hsl(0 0% 0% / 1.00);
--shadow-2xl: 4px 4px 0px 0px hsl(0 0% 0% / 2.50);
```

## 5. 圆角 (Border Radius)

为了体现“锐利”感，所有圆角都设置为 0。

```css
--radius: 0px;
--radius-sm: -4px; /* 实际应用中可能需要调整或避免负值 */
--radius-md: -2px; /* 实际应用中可能需要调整或避免负值 */
--radius-lg: 0px;
--radius-xl: 4px;
```

## 6. 设计原则摘要 (Design Principles Summary)

- **Raw & Unrefined:** 拥抱“未完成”的美学。
- **High Contrast:** 大胆使用对比强烈的颜色和元素。
- **Asymmetric Layouts:** 采用非对称的布局方式。
- **Exposed Elements:** 明确展示按钮、边框等交互元素。
- **Bold Visuals:** 使用粗线条、大字体和鲜艳色彩。