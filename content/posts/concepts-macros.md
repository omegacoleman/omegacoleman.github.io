---
title:  "以版本兼容的方式使用c++20 concepts"
date:   2019-09-24T14:54:00+0800
draft:  false
---

c++20正式将Concept TS纳入了标准。这一feature解决了c++模版元编程长久以来存在的一个问题，就是没办法限制传入的模版参数，可能导致**上层写错的代码，报错信息出现在千里之外的地方**。

如果需要用的编译器不支持concepts怎么办呢？刚才提到了，仅仅用来检查输入参数的话，concept是一个没有实际功能的语法特性。这时候，我们可以利用宏做一个简单的polyfill：

``` c++

#pragma once

#ifdef __ENABLE_CONCEPTS

#define THE_TYPE TypeInDefConcept

#define DEF_CONCEPT(__name, __satisfy) template<typename THE_TYPE> \
	concept __name = requires __satisfy;

#define REQ_CONCEPT(__constraint) requires __constraint

#else

#define THE_TYPE

#define DEF_CONCEPT(__name, __satisfy)

#define REQ_CONCEPT(__constraint)

#endif


```

以cppreference上面对Concepts TS的范例来说，使用起来就是这样：

``` c++

#include "concepts.hpp"

#include <string>
#include <locale>
using namespace std::literals;

// Declaration of the concept "EqualityComparable", which is satisfied by
// any type T such that for values a and b of type T,
// the expression a==b compiles and its result is convertible to bool
DEF_CONCEPT(EqualityComparable,
		(THE_TYPE a, THE_TYPE b)
		{
		{ a == b } -> bool;
		})

template<typename T>
void f(T&&) REQ_CONCEPT(EqualityComparable<T>) {} // declaration of a constrained function template

int main() {
	f("abc"s); // OK, std::string is EqualityComparable
	f(std::use_facet<std::ctype<char>>(std::locale{})); // Error: not EqualityComparable
}

```

我们可以关闭concepts进行编译，并不会遇到任何问题：

```
[root@57e357a178c6 sema_concepts]# g++ test.cpp -o test -std=c++2a
[root@57e357a178c6 sema_concepts]#
```

在支持的编译器上打开开关并加入宏定义，就可以利用concepts检查出不合格的参数：

```
[root@57e357a178c6 sema_concepts]# g++ test.cpp -o test -std=c++2a -fconcepts -D__ENABLE_CONCEPTS
test.cpp: In function ‘int main()’:
test.cpp:21:51: error: cannot call function ‘void f(T&&) requires  EqualityComparable<T> [with T = const std::ctype<char>&]’
   21 |  f(std::use_facet<std::ctype<char>>(std::locale{})); // Error: not EqualityComparable
      |                                                   ^
test.cpp:17:6: note:   constraints not satisfied
   17 | void f(T&&) REQ_CONCEPT(EqualityComparable<T>) {} // declaration of a constrained function template
      |      ^
In file included from test.cpp:1:
test.cpp:10:13: note: within ‘template<class T> concept const bool EqualityComparable<T> [with T = const std::ctype<char>&]’
   10 | DEF_CONCEPT(EqualityComparable,
      |             ^~~~~~~~~~~~~~~~~~
……
```

