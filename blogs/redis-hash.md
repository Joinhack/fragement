---
title: redis的hash表
date: '2011-05-10'
description:
categories:
- redis
- Blog
tags:
- redis hash
---

redis的hash表
----------------
首先还是先说说hash表是什么？ 很多语言有不同的定义 java中的HashMap HashTable， golang中的map都是hash表的实现。大致原理如下：

hash表添加KEY-VALUE

	1). 将KEY计算hash，将KEY的hash值与bulks数求莫后找到对应bulk. 如果bulk有值循环整个bulk对应的KEY-VALUE 如果bulk中的KEY与加入的KEY相等 就覆盖其VALUE， 如果不等就追加到bulk后面。
	2). 达到占用bulks的阀值expand bulks, 遍历已有的数据重新加入扩展后的bulks中。
	3). 未达到阀值，完成hash插入操作。



hash表删除KEY

	1). 将KEY计算hash，将KEY的hash值与bulks数求莫后 找到对应的bulk。
	2). 遍历整个bulk依次对比KEY， 找到与KEY相等的KEY-VALUE将其移除。

hash表查找KEY的对象

	1). 将KEY计算hash，将KEY的hash值与bulks数求莫后 找到对应的bulk。
	2). 遍历整个bulk依次对比KEY， 找到与KEY相等的KEY-VALUE将VALUE返回。

上面就是hash表的工作原理。总体来说hash表的查询都是O(1) 删除也算是O(1), 从整体上来看也是一个O(1)操作， 这里不考虑hash碰撞的情况（如果碰撞最坏情况就变成O(N)）。 但是事实上如果插入非常频繁，从步骤就能看出, 就会经常expand， 这样插入肯定不会是O(1)的。

redis的提供的数据结构之一也是hash表，但是redis的hash表明显做的写优化， 就算是频繁插入也能达到O(1)的时间复杂度。下面就是redis的hash表结构。


