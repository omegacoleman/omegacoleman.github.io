---
title:  "c++中的CRTP"
date:   2020-01-27T00:18:20+0800
draft:  false
---

最近在学习`boost::beast`的时候，注意到了在自定义parser的地方，有这么一种设计：

``` c++
template<bool isRequest>
class custom_parser
    : public basic_parser<isRequest, custom_parser<isRequest>>
```

根据上面的说法，这种设计模式叫做CRTP，中文wiki翻译成"奇异递归模版模式"。其实这严格来说并不是个递归（两种类型互相分别为子类和模版参数），不过确实给了我耳目一新的感觉。

那么，什么是CRTP呢？CRTP是这样的一种设计模式：

1. 在需要使用类似于继承多态的地方使用
2. 将基类实现成模版类，例如：`A<Derived>`
3. 在派生类中，将派生类自己作为模版参数实体化基类模版，然后继承之：`class B : public A<B>`

本质上来说，CRTP是派生类对基类进行依赖注入的一种形式。

考虑如下的`A->B A->C`继承使用虚函数调用的情况：

``` c++
#include <iostream>

class A
{
	public:
		void call_func()
		{
			func();
		}

		virtual void func(){}
};

class B : public A
{
	public:
		virtual void func()
		{
			std::cout << "B.func" << std::endl;
		}
};

class C : public A
{
	public:
		virtual void func()
		{
			std::cout << "C.func" << std::endl;
		}
};

int main(void)
{
	B b;
	C c;
	b.call_func();
	c.call_func();
	return 0;
}
```

可能存在以下问题：

- 使用了虚表。虚表在cache miss的时候是非常慢的
- 每增加一个要转发到派生类的函数，就要多标记一次`virtual`
- 在基类中无法访问派生类，无法将由于派生类不合要求产生的错误提前到编译期

将上面的例子改成使用CRTP后，是这样的：

``` c++
#include <iostream>

template <class Derived>
class A
{
	public:
		void call_func()
		{
			static_cast<Derived*>(this)->func();
		}
};

class B : public A<B>
{
	public:
		void func()
		{
			std::cout << "B.func" << std::endl;
		}
};

class C : public A<C>
{
	public:
		void func()
		{
			std::cout << "C.func" << std::endl;
		}
};

int main(void)
{
	B b;
	C c;

	b.call_func();
	c.call_func();
	return 0;
}
```

除此之外，使用CRTP要注意几个问题：

1. 要将`this`转换成`Derived *`访问派生类成员，静态成员可以直接访问
2. 派生类并不能方便地cast成基类，不适用于依赖继承树多态的情况
3. 如果要访问`protected`或者`private`成员需要声明友元

