---
layout: post
title:  "Detecting memory leaks in c++ code"
date:   2018-08-18 12:00:00
categories: jekyll
---
Memory leaks are a very common problem in c++ development that can cause severe
problems due to difficult to found the problem.

##### Windows version [WIP]

Finding Memory Leaks Using the CRT Library

You can found all documentation on MSDN :

[Finding Memory Leaks Using the CRT Library](https://docs.microsoft.com/visualstudio/debugger/finding-memory-leaks-using-the-crt-library).

[Magic helper made by me](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/lib/include/memory_leak.h)

##### Linux & Mac version [WIP]
On Unix systems ASAN library from google will be used. This library is integrated in g++ and clang compilers and can be used as easy as setting a flag during comilation.

[example on github](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/CMakeLists.txt#L11)

The only thing we need to do is pass to the compiler the flags:

```
-g -O0 -fsanitize=leak"
```
-g: is for debugging symbols
-o0 is for don't optimization for accurate line number count
-fsanitize=leak is for activate ASAN with low overhead only detecting leaks.

Then when you start you application you will need to add an enviromental variable
[example on travis](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/.travis.yml#L107)

```
ASAN_OPTIONS=detect_leaks=1 ./app
```

with that done you will have something like this:
[travis build log](https://travis-ci.org/mercuriete/cpp-memory-leak-detection/jobs/417463458#L686)

```
Direct leak of 8 byte(s) in 1 object(s) allocated from:

 #0 0x7fb8069879f8 in operator new(unsigned long) (/usr/lib/x86_64-linux-gnu/liblsan.so.0+0xf9f8)

 #1 0x40bd8c in main /app/src/main.cpp:13

 #2 0x7fb8060a2f44 in __libc_start_main (/lib/x86_64-linux-gnu/libc.so.6+0x21f44)
```

then you can go to the [offending line](https://github.com/mercuriete/cpp-memory-leak-detection/blob/develop/app/src/main.cpp#L13)
 and check what is happening

```
string* leaking_pointer = new string("leaking object");

//You forgot to delete pointer

leaking_pointer = new string("Hello, World!");

cout << *leaking_pointer << endl;

delete leaking_pointer;
```

is really obvious whats going on. You forgot to delete a pointer before reuse for another instance.

##### Conclusions
Given that I have a bias about linux vs windows, Is obvious to understand that on the windows counterpart you have to modify your code a little bit in order to enable memory sanitizer tools.
With ASAN you only need to compile you code with debug symbols and ASAN will take care of analyze the heap for you.

Summarizing, there are some tools that can improve our code quality with a little bit of effort. This days are not acceptable to have such a problem comparing with days when instrumenting your application were more difficult.
