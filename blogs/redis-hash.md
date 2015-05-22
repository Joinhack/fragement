---
title: redis的hash表
date: '2015-05-10'
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

1. 将KEY计算hash，将KEY的hash值与slots数求莫后找到对应slot. 如果slot有值循环整个slot对应的KEY-VALUE 如果slot中的KEY与加入的KEY相等 就覆盖其VALUE， 如果不等就追加到slot后面。
2. 达到占用slots的阀值expand slots, 遍历已有的数据重新加入扩展后的slots中(rehashing)。
3. 未达到阀值，完成hash插入操作。


hash表删除KEY

1. 将KEY计算hash，将KEY的hash值与slots数求莫后 找到对应的slot。
2. 遍历整个slot依次对比KEY， 找到与KEY相等的KEY-VALUE将其移除。

hash表查找KEY的对象

1. 将KEY计算hash，将KEY的hash值与slots数求莫后 找到对应的slot。
2. 遍历整个slot依次对比KEY， 找到与KEY相等的KEY-VALUE将VALUE返回。

上面就是hash表的工作原理。总体来说hash表的查询都是O(1) 删除也算是O(1), 从整体上来看也是一个O(1)操作， 这里不考虑hash碰撞的情况（如果碰撞最坏情况就变成O(N)）。 但是事实上如果插入非常频繁，从步骤就能看出, 就会经常expand， 这样插入肯定不会是O(1)的。

redis的提供的数据结构之一也是hash表，但是redis的hash表明做了写优化， 就算是频繁插入也能达到O(1). 的时间复杂度。下面就是redis的hash表结构。

	//数据结果是从dict.h拷贝来的。
	typedef struct dictht {
	    dictEntry **table;  //这里就是上面提到的slots 一般是一个链表
	    unsigned long size;
	    unsigned long sizemask;
	    unsigned long used;
	} dictht;

	typedef struct dict {
	    dictType *type;
	    void *privdata;
	    dictht ht[2]; //2个dictht 这个就是用于写优化
	    long rehashidx; /* rehashing not in progress if rehashidx == -1 */
	    int iterators; /* number of iterators currently running */
	} dict;

redis 写优化结构的hash表 与普通hash表最主要的区别就是rehashing的时候移动动完所有的数据，而是将rehashing过程平摊到每次读写过程中去。


redis hash表添加KEY-VALUE (rehashing 过程中)

1. 将老表(dict中ht[0])中的一个KEY-VALUE移动到新表(dict中ht[1])中去。
2. 新表作中(dict中ht[0])slots作为添加数据的目标， 然后将KEY-VALUE添加入hash表。



hash表删除KEY (rehashing 过程中)

1. 如果将老表(dict中ht[0])中的一个KEY-VALUE移动到新表(dict中ht[1])中去。
2. 同时在将老表与新表中的依次找KEY，如果在老表中找到KEY就删除，无需再删除新表。


hash表删除KEY (rehashing 过程中)

1. 将老表(dict中ht[0])中的一个KEY-VALUE移动到新表(dict中ht[1])中去。
2. 同时在将老表与新表中的依次找KEY，如果在老表中找到KEY就返回，无需再找新表。

