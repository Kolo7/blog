# 用go填写pdf模板



## pdf格式分析

### 概述

PDF基本显示单元包括：文字，图片，矢量图，图片
PDF扩展单元包括：水印，电子署名，注释，表单，多媒体，3D
PDF动作单元：书签，超链接

### 优点

一致性、不易修改性、安全性、不失真、压缩。

### 对象

PDF文件是由对象集合组成的，包括：boolean（布尔型），numberic（数值型），string（字符串型），name（名字型），array（数组型），dictionary（字典型），stream（数据流型），null（空类型）， indirect（间接型）。

### 压缩

在PDF中，为了让文件变的更小，通常的做法是，将stream对象进行压缩，因为stream对象的数据块比较大，所以，是重点关注的地方。

一个stream对象，可以单次压缩，也可以多次压缩。/Filter [/ASCII85Decode /LZWDecode]，表示被描述的这个stream对象进行了ASCII85Decode和LZWDecode两次压缩，因此，对该stream进行解压缩的时候，也要按照反顺序解，分别压缩。
PDF支持的filter可以分为三大类：
一、ASCII filters（ASCIIHexDecode、ASCII85Decode），这种编码类型可以将8位二进制数据编码成ASCII文本。注意：这种类型的filter不能用在被加密的PDF文档中。
二、加密filters（LZWDecode、FlateDecode、RunLengthDecode、CCITTFaxDecode、JBIG2Decode、DCTDecode，JPXDecode），这些压缩类型包括无损压缩和有损压缩。
三、加密filter（Crypt）

### 文档结构

文件头：用来存储PDF版本
文件体：用来存储间接对象，这是构成PDF比重最大的内容
交叉索引表：用来保存各个间接对象在文件中的起始地址
trailer：用来存储交叉索引表的起始位置，根对象（Root），加密对象（Encrypt），文档信息对象（Info）等。

![pdf文件结构](https://img-blog.csdn.net/2018082217325989?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N0ZXZlX2N1aQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

PDF是一个大的对象集合，有个根对象（Root），该对象中保存着PDF的很多基本信息，并通过间接引用，辐射到所有的间接对象。
根对象下一层就是Pages对象，该对象保存着所有的页对象信息，默认页面的大小等等。
下一层是Page对象，该对象中包含页的各种属性，包括页面的大小（MediaBox，Cropbox等），图片信息，文本信息，字体信息等。

![这里写图片描述](https://img-blog.csdn.net/20180822175236281?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N0ZXZlX2N1aQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

### 交叉索引表

PDF交叉参考表是PDF文件的重要部分。该表保存了所有简介对象在PDF文件中物理偏移地址。该表在文件中可以存在单个，也可以存在多个。多个交叉引用表通常出现在两个情况：一、增量保存，二、线性化。

```
xref
0 47
0000000000 65535 f 
0000000009 00000 n 
0000042433 00000 n 
0000000195 00000 n 

```

交叉索引表的位置保存在文档的末尾

```
startxref
42531
```

### 增量更新

增量更新的工作方式如下：可以逐步更新PDF文件的内容，而无需重写整个文件。更改将附加到文件末尾，保留原始内容。

![这里写图片描述](https://img-blog.csdn.net/20180830174928941?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3N0ZXZlX2N1aQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)


已修改的每个对象都可以在PDF文件中找到两次。未修改的对象仍然存在于原始内容中，并且可以在更新的内容中找到相同对象的编辑版本。

更新内容的交叉引用表索引更新的对象，并且更新内容的尾部指向两个交叉引用表。

当PDF阅读器呈现PDF文档时，它从文件末尾开始。它读取最后一个预告片并跟随到根对象和交叉引用表的链接，以构建它将要呈现的文档的逻辑结构。当阅读器遇到更新的对象时，它会忽略相同对象的原始版本。


一个PDF文件允许增量更新的次数不受限制。
简单的判断PDF是否增量更新的方法是：**文档中存在多个“%%EOF”**。

如果制作增量更新的PDF，方法是按下列内容顺序输出：
1、原样输出PDF文件的内容
2、输出将修改或增加的间接对象
3、将更新的交叉引用表输出
4、输出trailer

### Catalog文档目录及page tree页面树

Catalog文档目录：是一个字典，它引用定义PDF文件的其他对象。基本上，Catalog就像是可以找到有关PDF文件的每个信息的中心。

1.

页面树（page tree）： 页面树是用于描述PDF文件中页面的结构的名称。它有两种类型的节点 - 页面树节点和页面对象。PDF文件中的每个页面都表示为Page对象。这些对象中的每一个在页面树中称为“叶子”节点。

- Type - 将始终是页面树节点的页面（Page）
- Parent - 作为此节点的父节点的页面树节点。根节点中不允许存在。
- Kids - 一个指向此节点的子节点的数组。子节点只能是页面树节点或页面对象
- Count - 作为此节点后代的页面对象总和

2.

页面对象：这是一个显示页面本身特征的字典。下面介绍一下常见的键：

- Type - 永远是Page
- Parent - 对此页面的父级的间接引用
- LastModified - 上次修改此页面的日期和时间
- Resource - 此页面所需的资源。这通常是指此页面上使用的字体和其他信息。
- MediaBox - 一个矩形，用于定义页面必须在其中显示的边界。
- Contents - 描述此页面内容的内容流。
- Rotate - 以90的倍数表示。在显示之前将页面旋转度数。
- Thumb - 一个流对象，为此页面提供缩略图图像。
- Dur - 在自动移动到下一页之前，页面将在演示文稿中显示的秒数。
- Trans - 一种字典，用于指示在演示期间显示页面时要使用的转换。
- Annots - 这是一个字典数组，包含对此页面的所有注释的引用
- AA - 这是附加行动的简短形式。此字典定义文件打开或关闭时需要采取的操作。
- Metadata - 包含此页面元数据的流

页面属性是继承的：页面中的某些属性可以从其父页面或页面树中的任何祖先继承。消除了为每个子节点，孙子节点等重复保持类似属性的需要。如果祖先定义了属性的值，则该值可以由子节点替换或更改。

3.

内容流：这是一个流对象，其中包含有关如何在相应页面上显示文本和图形的说明。

### Viewer Preferences

在catalog字典中，保存着PDF文档的查看器打开PDF文档在屏幕上或打印中的显示方式，该键是ViewerPreferences。

### PageLayout和PageMode

两者都是Catalog中的键：

pageLatout：打开文档时，浏览器应该使用的页面布局。

PageMode：一个名称对象，指定打开时文档的显示方式。

### 书签 outlines

PDF文档支持文件大纲（书签），用户可以通过点击书签完成跳转功能。

常用的跳转功能有：

- 跳转到文档内部页面
- 跳转到其他PDF文档的某一页
- 跳转到web页面
- 跳转到外部文件（非PDF）

书签是一个树状结构，根据遍历“First”，“Next”，得到完整的书签节点。

```
17 0 obj
<</Type /Outlines /First 18 0 R
/Last 18 0 R>>
endobj
```

### 了解更多

[pdf结构分析博客合集](https://me.csdn.net/blog/steve_cui)

## go处理PDF的库

### signintech/gopdf

仓库地址

> github.com/signintech/gopdf

go mod

> github.com/signintech/gopdf 

free，可处理中文，支持读入pdf模板，有案例，不支持表格处理。



### tiechui1994/gopdf

仓库地址

> github.com/tiechui1994/gopdf

go mod

>github.com/tiechui1994/gopdf 

free，可处理中文，支持读入pdf模板，支持表格生成，缺乏案例。

### unidoc/unipdf

仓库地址

> github.com\unidoc\unipdf

go mod

> github.com\unidoc\unipdf v3

比其他两个更加专业，能够自动的生成更多种类的结构，但收费。

## 难点分析

直接后端用模板填写生成pdf文件的问题在于格式要求难以维持。

### 表格问题

go现有的库对表格绘制支持差，无法定制表格，可以通过在页上绘制线段来解决。

需要同时处理换页问题。画出来的表格超过了页的最大限度就要计算把多出来的行画到下一页。列不会超过限度，但是在列数量较多时，单列内的文字应该不能完全展示或者是换行，实际效果保持需要联动文字和表格的关系，具体计算再具体展示。

### 模板变形问题

对模板的填充会导致模板原有的布局发生改变，而绘制pdf中的各类对象（图片、段落、表格）之间不存在逻辑关系，对象间可以重叠覆盖，因此直接绘制pdf是难以保证自动布局变动。

## 总结

pdf的格式调整困难导致了pdf不适合直接动态生成，而是适合通过其他的格式转换。
